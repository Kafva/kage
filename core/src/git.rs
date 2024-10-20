use once_cell::sync::Lazy;
use std::path::Path;
use std::sync::Mutex;
use std::sync::MutexGuard;
use std::sync::Once;

use git2::build::RepoBuilder;
use git2::opts::{
    get_server_connect_timeout_in_milliseconds,
    get_server_timeout_in_milliseconds,
    set_server_connect_timeout_in_milliseconds,
    set_server_timeout_in_milliseconds,
};

use git2::{FetchOptions, RemoteCallbacks, Repository};

#[cfg(not(target_os = "android"))]
use git2::build::CheckoutBuilder;

use crate::*;

const TRANSFER_STAGES: usize = 4;
#[cfg(not(target_os = "android"))]
const GIT_EMAIL: &'static str = env!("KAGE_GIT_EMAIL");

#[cfg(not(test))]
const GIT_REMOTE: &'static str = env!("KAGE_GIT_REMOTE");
#[cfg(test)]
pub const GIT_REMOTE: &'static str = env!("KAGE_GIT_REMOTE");

#[cfg(not(test))]
const GIT_BRANCH: &'static str = env!("KAGE_GIT_BRANCH");
#[cfg(test)]
pub const GIT_BRANCH: &'static str = env!("KAGE_GIT_BRANCH");

/// Persistent library state for last error that occurred
/// The git2::Error::last_error() method does not fit our needs, the error
/// message we want to show tends to be overwritten from later successful
/// invocations of git functions before we can retrieve it.
static GIT_LAST_ERROR: Lazy<Mutex<Option<git2::Error>>> =
    Lazy::new(|| Mutex::new(None));

static ONCE: Once = Once::new();

#[macro_export]
macro_rules! git_call {
    ($result:expr, $last_error:ident) => {
        match $result {
            Ok(_) => 0,
            Err(err) => {
                error!("{}", err);
                *$last_error = Some(err);
                $last_error.as_ref().unwrap().raw_code()
            }
        }
    };
}

#[cfg(not(target_os = "android"))]
macro_rules! internal_error {
    () => {
        git2::Error::new(
            git2::ErrorCode::GenericError,
            git2::ErrorClass::None,
            "Internal error",
        )
    };
}

/// One-time initialization of the underlying library
pub fn git_setup() {
    ONCE.call_once(|| git_init_opts().expect("Error initializing libgit2"));
}

#[cfg(not(target_os = "android"))]
pub fn git_pull(repo_path: &str) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    let mut remote = repo.find_remote(GIT_REMOTE)?;

    // Fetch remote changes
    let mut cb = git2::RemoteCallbacks::new();
    let mut fopts = git2::FetchOptions::new();
    cb.transfer_progress(|progress| transfer_progress(progress, "Fetching"));
    fopts.remote_callbacks(cb);

    remote.fetch(&[GIT_BRANCH], Some(&mut fopts), None)?;

    // Update the local checkout to use the remote head (fast-forward)
    let remote_origin_head = remote_branch_oid(&repo)?;
    let remote_origin_head = repo.find_annotated_commit(remote_origin_head)?;

    let analysis = repo.merge_analysis(&[&remote_origin_head])?;

    if analysis.0.is_up_to_date() {
        debug!("Already up to date.");
    } else if analysis.0.is_fast_forward() {
        let head_ref_name = format!("refs/heads/{}", GIT_BRANCH);
        let mut head_reference = repo.find_reference(&head_ref_name)?;

        let reflog_message = format!(
            "Fast-Forward: {} -> {}",
            head_ref_name,
            remote_origin_head.id()
        );
        debug!("{}", reflog_message);
        head_reference.set_target(remote_origin_head.id(), &reflog_message)?;
        repo.set_head(&head_ref_name)?;
        repo.checkout_head(Some(CheckoutBuilder::default().force()))?;
    } else {
        debug!("Cannot fast-forward");
        return Err(git2::Error::new(
            git2::ErrorCode::NotFastForward,
            git2::ErrorClass::None,
            "Cannot fast-forward",
        ));
    }
    Ok(())
}

#[cfg(not(target_os = "android"))]
pub fn git_push(repo_path: &str) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    let mut remote = repo.find_remote(GIT_REMOTE)?;

    let mut push_options = git2::PushOptions::new();
    let mut remote_callbacks = git2::RemoteCallbacks::new();

    remote_callbacks.push_transfer_progress(|current, total, _| {
        if current == total {
            debug!("Pushing: [{:4} / {:4}] Done", current, total);
            return;
        }

        if total <= TRANSFER_STAGES {
            return;
        }

        let increments = total / TRANSFER_STAGES;
        if current % increments == 0 {
            debug!("Pushing: [{:4} / {:4}]", current, total);
        }
    });
    push_options.remote_callbacks(remote_callbacks);

    let mut refspecs = [format!("refs/heads/{}", GIT_BRANCH)];
    remote.push(&mut refspecs, Some(&mut push_options))?;

    Ok(())
}

#[cfg(not(target_os = "android"))]
pub fn git_stage(
    repo_path: &str,
    relative_path: &str,
) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    let mut index = repo.index()?;

    let cb = &mut |path: &Path, _matched_spec: &[u8]| -> i32 {
        let Some(path_str) = path.to_str() else {
            error!("Empty path encountered in '{}'", relative_path);
            return 1;
        };

        let Ok(status) = repo.status_file(path) else {
            warn!("Unknown status: '{}'", path_str);
            return 1;
        };

        match status {
            git2::Status::WT_MODIFIED => {
                debug!("Modified: '{}'", path_str);
                0
            }
            git2::Status::WT_NEW => {
                debug!("Added: '{}'", path_str);
                0
            }
            git2::Status::WT_DELETED => {
                debug!("Deleted: '{}'", path_str);
                0
            }
            git2::Status::WT_RENAMED => {
                debug!("Renamed: '{:?}'", path_str);
                0
            }
            _ => 1,
        }
    };

    // The callback is only invoked for filepaths (leafs), not directories.
    // An empty directory will not give any errors
    index.add_all(
        Some(relative_path),
        git2::IndexAddOption::DEFAULT,
        Some(cb),
    )?;
    index.write()
}

#[cfg(not(target_os = "android"))]
pub fn git_commit(repo_path: &str, message: &str) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    // Retrieve the commit that HEAD points to so that we can replace
    // it with our new tree state.
    let head = repo.head()?;
    let mut index = repo.index()?;
    let statuses = repo.statuses(None)?;

    let is_clean = statuses.iter().all(|entry| {
        let status = entry.status();
        status.is_empty()
    });

    if is_clean {
        error!("Refusing to create empty commit");
        return Err(internal_error!());
    }

    let sig = repo.signature()?;
    let tree_id = index.write_tree()?;
    let tree = repo.find_tree(tree_id)?;

    let Some(oid) = head.target() else {
        error!("HEAD unwrap error");
        return Err(internal_error!());
    };
    let parent_commit = repo.find_commit(oid)?;

    let _oid = repo.commit(
        Some("HEAD"),
        &sig,
        &sig,
        message,
        &tree,
        &[&parent_commit],
    )?;

    debug!("[{} {:.7}] {}", GIT_BRANCH, _oid, message);
    Ok(())
}

/// Hard reset to the local HEAD, discarding all uncommited (and staged) local
/// changes. Note: untracked files and directories that have not been staged
/// need to be manually removed.
#[cfg(not(target_os = "android"))]
pub fn git_reset(repo_path: &str) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    let local_head = repo.revparse_single(GIT_BRANCH)?.id();

    debug!("Resetting HEAD to {} {}", GIT_BRANCH, local_head);

    let obj = repo.find_object(local_head, None)?;
    repo.reset(&obj, git2::ResetType::Hard, None)
}

pub fn git_clone(url: &str, into: &str) -> Result<(), git2::Error> {
    let mut cb = RemoteCallbacks::new();
    cb.transfer_progress(|progress| transfer_progress(progress, "Cloning"));

    let mut fopts = FetchOptions::new();
    fopts.remote_callbacks(cb);

    RepoBuilder::new()
        .fetch_options(fopts)
        .clone(url, Path::new(into))?;
    Ok(())
}

/// Returns true if remote and local HEAD are equal
#[cfg(not(target_os = "android"))]
pub fn git_local_head_matches_remote(
    repo_path: &str,
) -> Result<bool, git2::Error> {
    let repo = Repository::open(repo_path)?;
    let head = repo.head()?;

    let remote_oid = remote_branch_oid(&repo)?;
    let Some(local_oid) = head.target() else {
        warn!("Could not determine local HEAD");
        return Ok(false);
    };

    Ok(local_oid == remote_oid)
}

#[cfg(not(target_os = "android"))]
pub fn git_config_set_user(
    repo_path: &str,
    username: &str,
) -> Result<(), git2::Error> {
    let config_path = Path::new(repo_path).join(".git").join("config");
    let mut cfg = git2::Config::open(&config_path)?;

    cfg.set_str("user.name", username)?;
    cfg.set_str("user.email", &format!("{}@{}", username, GIT_EMAIL))?;

    // Echoing back the config gives errors...
    //  https://github.com/rust-lang/git-rs/issues/474
    Ok(())
}

/// Returns an array of "<timestamp>\n<oid>\n<summary>" strings for all commits.
/// The first commit will be the last entry in the array
pub fn git_log(repo_path: &str) -> Result<Vec<String>, git2::Error> {
    let repo = Repository::open(repo_path)?;
    let mut revwalk = repo.revwalk()?;
    let remote_oid = remote_branch_oid(&repo)?;

    let mut arr = vec![];
    revwalk.push_head()?;
    for c in revwalk {
        let Ok(oid) = c else { break };
        let Ok(commit) = repo.find_commit(oid) else {
            break;
        };
        let Some(summary) = commit.summary() else {
            break;
        };

        // Prettify the remote head
        let revstr = if oid == remote_oid {
            format!("{}/{}", GIT_REMOTE, GIT_BRANCH)
        } else {
            oid.to_string()
        };

        let commit_info = format!(
            "{}\n{}\n{}",
            commit.time().seconds(),
            revstr,
            summary.to_string(),
        );
        arr.push(commit_info)
    }
    Ok(arr)
}

/// Acquire the last error mutex, should be called before each method call
/// in a multithreaded environment.
pub fn git_try_lock() -> Option<MutexGuard<'static, Option<git2::Error>>> {
    let Ok(git_last_error) = GIT_LAST_ERROR.try_lock() else {
        error!("Mutex lock already taken");
        return None;
    };
    Some(git_last_error)
}

/// Initialize global options in the underlying library
fn git_init_opts() -> Result<(), git2::Error> {
    unsafe {
        #[cfg(not(test))]
        {
            set_server_timeout_in_milliseconds(5000)?;
            set_server_connect_timeout_in_milliseconds(5000)?;
        }

        #[cfg(test)]
        {
            set_server_timeout_in_milliseconds(1000)?;
            set_server_connect_timeout_in_milliseconds(1000)?;
        }

        let timeout = get_server_timeout_in_milliseconds()?;
        let connect_timeout = get_server_connect_timeout_in_milliseconds()?;

        debug_safe!("Configured read/write timeout: {} ms", timeout);
        debug_safe!("Configured connect timeout: {} ms", connect_timeout);
    };
    Ok(())
}

fn remote_branch_oid(
    repo: &git2::Repository,
) -> Result<git2::Oid, git2::Error> {
    let spec = format!("{}/{}", GIT_REMOTE, GIT_BRANCH);
    let id = repo.revparse_single(&spec)?.id();
    Ok(id)
}

fn transfer_progress(progress: git2::Progress, _label: &str) -> bool {
    let total = progress.total_objects();
    let total_deltas = progress.total_deltas();
    if total <= TRANSFER_STAGES {
        return true;
    }

    let indexed = progress.indexed_objects();
    let recv = progress.received_objects();
    let deltas = progress.indexed_deltas();
    let increments = total / TRANSFER_STAGES;

    if recv % increments == 0 {
        if recv == total && (indexed < total || deltas < total_deltas) {
            /* skip */
        } else {
            debug!("{}: [{:4} / {:4}]", _label, recv, total);
        }
    } else if recv == total && indexed == total && deltas == total_deltas {
        debug!("{}: [{:4} / {:4}] Done", _label, recv, total);
    }

    true
}
