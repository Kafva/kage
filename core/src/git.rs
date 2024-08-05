use std::net::TcpStream;
use std::path::Path;
use std::time::Duration;

use git2::build::{CheckoutBuilder, RepoBuilder};
use git2::{FetchOptions, RemoteCallbacks, Repository};

use crate::*;

const TRANSFER_STAGES: usize = 4;
const GIT_EMAIL: &'static str = env!("KAGE_GIT_EMAIL");

#[cfg(not(test))]
const GIT_REMOTE: &'static str = env!("KAGE_GIT_REMOTE");
#[cfg(test)]
pub const GIT_REMOTE: &'static str = env!("KAGE_GIT_REMOTE");

#[cfg(not(test))]
const GIT_BRANCH: &'static str = env!("KAGE_GIT_BRANCH");
#[cfg(test)]
pub const GIT_BRANCH: &'static str = env!("KAGE_GIT_BRANCH");

#[cfg(not(test))]
const GIT_CLONE_TIMEOUT: u64 = 5;
#[cfg(test)]
const GIT_CLONE_TIMEOUT: u64 = 1;

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

    index.add_all(
        Some(relative_path),
        git2::IndexAddOption::DEFAULT,
        Some(cb),
    )?;
    index.write()
}

pub fn git_commit(repo_path: &str, message: &str) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    let sig = repo.signature()?;

    let mut index = repo.index()?;
    let tree_id = index.write_tree()?;
    let tree = repo.find_tree(tree_id)?;

    // Retrieve the commit that HEAD points to so that we can replace
    // it with our new tree state.
    let head = repo.head()?;
    let Some(oid) = head.target() else {
        return Err(internal_error("HEAD unwrap error"));
    };
    let parent_commit = repo.find_commit(oid)?;

    let oid = repo.commit(
        Some("HEAD"),
        &sig,
        &sig,
        message,
        &tree,
        &[&parent_commit],
    )?;

    debug!("[{} {:.7}] {}", GIT_BRANCH, oid, message);
    Ok(())
}

/// Hard reset to the remote HEAD, discarding local commits that have not
/// been pushed.
pub fn git_reset(repo_path: &str) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    let remote_origin_head = remote_branch_oid(&repo)?;

    debug!(
        "Resetting HEAD to {}/{} {}",
        GIT_REMOTE, GIT_BRANCH, remote_origin_head
    );

    let obj = repo.find_object(remote_origin_head, None)?;
    repo.reset(&obj, git2::ResetType::Hard, None)
}

pub fn git_clone(url: &str, into: &str) -> Result<(), git2::Error> {
    if let Err(err) =
        try_tcp_connect(url, Duration::from_secs(GIT_CLONE_TIMEOUT))
    {
        error!("{}", err);
        return Err(err);
    };

    let mut cb = RemoteCallbacks::new();
    cb.transfer_progress(|progress| transfer_progress(progress, "Cloning"));

    let mut fopts = FetchOptions::new();
    fopts.remote_callbacks(cb);

    RepoBuilder::new()
        .fetch_options(fopts)
        .clone(url, Path::new(into))?;
    Ok(())
}

/// Returns true if there are no uncommitted changes and nothing to push
pub fn git_index_has_local_changes(
    repo_path: &str,
) -> Result<bool, git2::Error> {
    let repo = Repository::open(repo_path)?;
    let head = repo.head()?;
    let statuses = repo.statuses(None)?;

    let is_clean = statuses.iter().all(|entry| {
        let status = entry.status();
        status.is_empty()
    });

    let remote_oid = remote_branch_oid(&repo)?;
    let Some(local_oid) = head.target() else {
        warn!("Could not determine local HEAD");
        return Ok(false);
    };

    Ok(!is_clean || local_oid != remote_oid)
}

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

fn remote_branch_oid(
    repo: &git2::Repository,
) -> Result<git2::Oid, git2::Error> {
    let spec = format!("{}/{}", GIT_REMOTE, GIT_BRANCH);
    let id = repo.revparse_single(&spec)?.id();
    Ok(id)
}

fn transfer_progress(progress: git2::Progress, label: &str) -> bool {
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
            debug!("{}: [{:4} / {:4}]", label, recv, total);
        }
    } else if recv == total && indexed == total && deltas == total_deltas {
        debug!("{}: [{:4} / {:4}] Done", label, recv, total);
    }

    true
}

fn try_tcp_connect(url: &str, timeout: Duration) -> Result<(), git2::Error> {
    let Some(address) = url.strip_prefix("git://") else {
        return Err(internal_error("Invalid protocol for remote address"));
    };

    let Some(spl) = address.split_once("/") else {
        return Err(internal_error("Error parsing remote address"));
    };

    // Fallback to default git daemon port
    let address: String;
    let colon_count = spl.0.chars().filter(|c| *c == ':').count();

    if colon_count == 0 {
        address = spl.0.to_string() + ":9418";
    } else if colon_count == 1 {
        address = spl.0.to_string()
    } else {
        return Err(internal_error("Error parsing remote address"));
    }

    let Ok(sockaddr) = address.parse() else {
        return Err(internal_error("Error parsing remote address"));
    };

    match TcpStream::connect_timeout(&sockaddr, timeout) {
        Ok(_) => Ok(()),
        Err(err) => {
            let msg = &format!("Error connecting to remote address: {}", err);
            Err(internal_error(msg))
        }
    }
}

fn internal_error(message: &str) -> git2::Error {
    git2::Error::new(
        git2::ErrorCode::GenericError,
        git2::ErrorClass::None,
        message,
    )
}