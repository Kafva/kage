use std::path::Path;

use git2::{RemoteCallbacks,FetchOptions,Repository};
use git2::build::{CheckoutBuilder,RepoBuilder};

use crate::*;

const GIT_REMOTE: &'static str = "origin";
const GIT_BRANCH: &'static str = "main";
const TRANSFER_STAGES: usize = 4;

pub fn git_pull(repo_path: &str) -> Result<(),git2::Error> {
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

        let reflog_message = format!("Fast-Forward: {} -> {}",
                                      head_ref_name,
                                      remote_origin_head.id());
        debug!("{}", reflog_message);
        head_reference.set_target(remote_origin_head.id(), &reflog_message)?;
        repo.set_head(&head_ref_name)?;
        repo.checkout_head(Some(CheckoutBuilder::default().force()))?;

    } else {
        debug!("Cannot fast-forward");
        return Err(git2::Error::new(git2::ErrorCode::NotFastForward,
                                    git2::ErrorClass::None,
                                    "Cannot fast-forward"))
    }
    Ok(())
}

pub fn git_push(repo_path: &str) -> Result<(),git2::Error> {
    let repo = Repository::open(repo_path)?;
    let mut remote = repo.find_remote(GIT_REMOTE)?;

    let mut push_options = git2::PushOptions::new();
    let mut remote_callbacks = git2::RemoteCallbacks::new();

    remote_callbacks.push_transfer_progress(|current, total, _| {
        if total <= TRANSFER_STAGES {
            return
        }

        let increments = total / TRANSFER_STAGES;
        if current == total {
            debug!("Pushing: Done");
        }
        else if current % increments == 0 {
            debug!("Pushing: [{:4} / {:4}]", current, total);
        }
    });
    push_options.remote_callbacks(remote_callbacks);

    let mut refspecs = [format!("refs/heads/{}", GIT_BRANCH)];
    remote.push(&mut refspecs, Some(&mut push_options))?;

    Ok(())
}

pub fn git_stage(repo_path: &str, relative_path: &str, add: bool) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    let mut index = repo.index()?;
    let relative_path = Path::new(relative_path);
    if add {
        index.add_path(relative_path)?;
    } else {
        index.remove_path(relative_path)?;
    }
    index.write()
}

pub fn git_commit(repo_path: &str, message: &str) -> Result<(),git2::Error> {
    let repo = Repository::open(repo_path)?;
    let sig = repo.signature()?;

    let mut index = repo.index()?;
    let tree_id = index.write_tree()?;
    let tree = repo.find_tree(tree_id)?;

    // Retrieve the commit that HEAD points to so that we can replace
    // it with our new tree state.
    let head = repo.head()?;
    let Some(oid) = head.target() else {
        return Err(internal_error("HEAD unwrap error"))
    };
    let parent_commit = repo.find_commit(oid)?;

    repo.commit(
        Some("HEAD"),
        &sig,
        &sig,
        message,
        &tree,
        &[&parent_commit],
    )?;
    Ok(())
}

pub fn git_reset(repo_path: &str) -> Result<(),git2::Error> {
    let repo = Repository::open(repo_path)?;
    let head = repo.head()?;
    let Some(oid) = head.target() else {
        return Err(internal_error("HEAD unwrap error"))
    };
    let obj = repo.find_object(oid, None)?;

    debug!("Reset HEAD to {}", oid);
    repo.reset(&obj, git2::ResetType::Hard, None)
}

pub fn git_clone(url: &str, into: &str) -> Result<(), git2::Error> {
    let mut cb = RemoteCallbacks::new();
    cb.transfer_progress(|progress| transfer_progress(progress, "Cloning"));

    let mut fopts = FetchOptions::new();
    fopts.remote_callbacks(cb);

    RepoBuilder::new().fetch_options(fopts).clone(url, Path::new(into))?;
    Ok(())
}

/// Returns true if there are no uncommitted changes and nothing to push
pub fn git_index_has_local_changes(repo_path: &str) -> Result<bool, git2::Error> {
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
        return Ok(false)
    };

    Ok(!is_clean || local_oid != remote_oid)
}

fn remote_branch_oid(repo: &git2::Repository) -> Result<git2::Oid, git2::Error> {
    let spec = format!("{}/{}", GIT_REMOTE, GIT_BRANCH);
    let id = repo.revparse_single(&spec)?.id();
    Ok(id)
}

fn transfer_progress(progress: git2::Progress, label: &str) -> bool {
    let total = progress.total_objects();
    let total_deltas = progress.total_deltas();
    if total <= TRANSFER_STAGES {
        return true
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
    }
    else if recv == total && indexed == total && deltas == total_deltas {
        debug!("{}: Done", label);
    }

    true
}

fn internal_error(message: &str) -> git2::Error {
    git2::Error::new(git2::ErrorCode::GenericError,
                     git2::ErrorClass::None,
                     message)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::error;
    use std::fs;
    use std::process::Command;
    use std::time::{SystemTime, UNIX_EPOCH};

    const REPO_PATH: &'static str = "../git/kage-client/james";
    const EXTERNAL_CHECKOUT: &'static str = "/tmp/james";

    fn assert_ok(result: Result<(), git2::Error>) {
        if let Some(err) = result.as_ref().err() {
            error!("{}", err);
        }
        assert!(result.is_ok())
    }

    fn clone(path: &str) {
        // Remove previous checkout if needed
        if let Err(err) = fs::remove_dir_all(path) {
            match err.kind() {
                std::io::ErrorKind::NotFound => (),
                _ => panic!("{}", err)
            }
        }

        assert_ok(git_clone("git://127.0.0.1/james", path));
    }

    /// Test: 
    ///    1. Clone -> add -> commit -> push 
    ///    2. Pull in remote changes
    ///    3. Do local changes and reset
    #[test]
    fn git_clone_test() {
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap();
        // File added by us
        let newfile = format!("newfile-{}", now.as_secs());
        let newfile_path = format!("{}/{}", REPO_PATH, newfile);

        // File added from another checkout and pulled down
        let externalfile = format!("externalfile-{}", now.as_secs());
        let externalfile_path = format!("{}/{}", EXTERNAL_CHECKOUT, externalfile);
        let pulled_externalfile_path = format!("{}/{}", REPO_PATH, externalfile);

        clone(REPO_PATH);

        // Add
        fs::write(&newfile_path, "Original content").expect("write file failed");
        assert_ok(git_stage(REPO_PATH, &newfile, true));
        assert_eq!(git_index_has_local_changes(REPO_PATH).unwrap(), true);

        // Commit
        assert_ok(git_commit(REPO_PATH, format!("Adding {}", newfile).as_str()));
        assert_eq!(git_index_has_local_changes(REPO_PATH).unwrap(), true);

        // Push
        assert_ok(git_push(REPO_PATH));
        assert_eq!(git_index_has_local_changes(REPO_PATH).unwrap(), false);

        // Nothing to do
        assert_ok(git_pull(REPO_PATH));

        // Clone into a new location, add, commit and push from here
        clone(EXTERNAL_CHECKOUT);

        fs::write(&externalfile_path, "External content").expect("write file failed");
        let status = Command::new("git").arg("add")
                                        .arg(&externalfile)
                                        .current_dir(EXTERNAL_CHECKOUT)
                                        .status()
                                        .expect("command failed");
        assert!(status.success());

        let status = Command::new("git").arg("commit")
                                        .arg("-q")
                                        .arg("-m")
                                        .arg(format!("Adding {}", &externalfile))
                                        .current_dir(EXTERNAL_CHECKOUT)
                                        .status()
                                        .expect("command failed");
        assert!(status.success());

        let status = Command::new("git").arg("push")
                                        .arg("-q")
                                        .arg(GIT_REMOTE)
                                        .arg(GIT_BRANCH)
                                        .current_dir(EXTERNAL_CHECKOUT)
                                        .status()
                                        .expect("command failed");
        assert!(status.success());

        // Pull in external updates
        assert_ok(git_pull(REPO_PATH));

        // Stage some changes
        fs::remove_file(&pulled_externalfile_path).expect("remove file failed");
        let original_data = fs::read(&newfile_path).expect("read file failed");
        fs::write(&newfile_path, "Changed content").expect("write file failed");

        assert_ok(git_stage(REPO_PATH, &externalfile, false));
        assert_ok(git_stage(REPO_PATH, &newfile, true));

        assert!(fs::metadata(&pulled_externalfile_path).is_err());
        assert!(fs::metadata(&newfile_path).is_ok());

        // Reset
        assert_ok(git_reset(REPO_PATH));

        // Verify that changes were restored
        assert!(fs::metadata(&pulled_externalfile_path).is_ok());
        let data = fs::read(&newfile_path).expect("read file failed");
        assert_eq!(data, original_data)
    }
}
