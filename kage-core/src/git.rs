use std::path::Path;

use git2::{RemoteCallbacks,FetchOptions,Repository};
use git2::build::{CheckoutBuilder,RepoBuilder};

use crate::*;

const GIT_EMAIL: &'static str = "kafva.one";
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
        if current == total {
            debug!("Pushing: [{:4} / {:4}] Done", current, total);
            return
        }

        if total <= TRANSFER_STAGES {
            return
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

pub fn git_stage(repo_path: &str,
                 relative_path: &str,
                 add: bool) -> Result<(), git2::Error> {
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
pub fn git_reset(repo_path: &str) -> Result<(),git2::Error> {
    let repo = Repository::open(repo_path)?;
    let remote_origin_head = remote_branch_oid(&repo)?;

    debug!("Resetting HEAD to {}/{} {}", GIT_REMOTE, GIT_BRANCH, remote_origin_head);

    let obj = repo.find_object(remote_origin_head, None)?;
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

pub fn git_config_set_user(repo_path: &str, username: &str) -> Result<(), git2::Error> {
    let config_path = Path::new(repo_path).join(".git").join("config");
    let mut cfg = git2::Config::open(&config_path)?;

    cfg.set_str("user.name", username)?;
    cfg.set_str("user.email", &format!("{}@{}", username, GIT_EMAIL))?;

    // Echoing back the config gives errors...
    //  https://github.com/rust-lang/git-rs/issues/474
    Ok(())
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
        debug!("{}: [{:4} / {:4}] Done", label, recv, total);
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

    const GIT_USERNAME: &'static str = "james";
    const GIT_REMOTE_CLONE_URL: &'static str = "git://127.0.0.1/tests";
    const GIT_CLIENT_DIR: &'static str = "../git/kage-client/tests";

    fn assert_ok(result: Result<(), git2::Error>) {
        if let Some(err) = result.as_ref().err() {
            error!("{}", err);
        }
        assert!(result.is_ok())
    }

    fn rm_rf(path: &str) {
        let Err(err) = fs::remove_dir_all(path) else {
            return
        };

        match err.kind() {
            std::io::ErrorKind::NotFound => (),
            _ => panic!("{}", err)
        }
    }

    fn clone(url: &str, into: &str) {
        // Remove previous checkout if needed
        rm_rf(into);

        assert_ok(git_clone(url, into));
        assert_ok(git_config_set_user(into, GIT_USERNAME));
    }

    #[test]
    /// Test that we can add a directory
    fn git_directory_test() {

    }

    #[test]
    /// Test that we can reset to the remote head commit in a local checkout
    fn git_reset_test() {
        let remote_path = &format!("{}/reset_test", GIT_REMOTE_CLONE_URL);
        let repo_path = &format!("{}/reset_test", GIT_CLIENT_DIR);

        let file_to_keep = "file_to_keep";
        let file_to_remove = "file_to_remove";
        let file_to_modify = "file_to_modify";

        let file_to_keep_path = format!("{}/{}", repo_path, file_to_keep);
        let file_to_remove_path = format!("{}/{}", repo_path, file_to_remove);
        let file_to_modify_path = format!("{}/{}", repo_path, file_to_modify);

        let original_data = "To modify";

        clone(remote_path, repo_path);

        // Create a commit with all three files
        fs::write(&file_to_keep_path, "To keep").expect("write file failed");
        fs::write(&file_to_remove_path, "To remove").expect("write file failed");
        fs::write(&file_to_modify_path, original_data).expect("write file failed");
        assert_ok(git_stage(repo_path, &file_to_keep, true));
        assert_ok(git_stage(repo_path, &file_to_remove, true));
        assert_ok(git_stage(repo_path, &file_to_modify, true));
        assert_ok(git_commit(repo_path, "Test commit"));
        assert_ok(git_push(repo_path));

        // Stage some changes to them and commit
        fs::remove_file(&file_to_remove_path).expect("remove file failed");
        fs::write(&file_to_modify_path, "Different content").expect("write file failed");

        assert_ok(git_stage(repo_path, &file_to_remove, false));
        assert_ok(git_stage(repo_path, &file_to_modify, true));
        assert_ok(git_commit(repo_path, "Commit to undo"));

        assert!(fs::metadata(&file_to_keep_path).is_ok());
        assert!(fs::metadata(&file_to_remove_path).is_err());
        assert!(fs::metadata(&file_to_modify_path).is_ok());

        // Reset
        assert_ok(git_reset(repo_path));

        // Verify that changes were restored
        assert!(fs::metadata(&file_to_keep_path).is_ok());
        assert!(fs::metadata(&file_to_remove_path).is_ok());
        let data = fs::read(&file_to_modify_path).expect("read file failed");
        assert_eq!(data, original_data.as_bytes())
    }

    #[test]
    /// Test that we can pull in new changes from our remote
    fn git_pull_test() {
        let remote_path = &format!("{}/pull_test", GIT_REMOTE_CLONE_URL);
        let repo_path = &format!("{}/pull_test", GIT_CLIENT_DIR);

        let file_to_keep = "our_file";
        let file_to_keep_path = format!("{}/{}", repo_path, file_to_keep);

        clone(remote_path, repo_path);

        // Create a commit with all three files
        fs::write(&file_to_keep_path, "To keep").expect("write file failed");
        assert_ok(git_stage(repo_path, &file_to_keep, true));
        assert_ok(git_commit(repo_path, "Test commit"));
        assert_ok(git_push(repo_path));

        // Nothing to do
        assert_ok(git_pull(repo_path));

        // Clone into a new location, add, commit and push from here
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap();
        let external_client_path = &format!("/tmp/.pull_test-{}", now.as_secs());
        // Use the current time as a suffix for the new file to ensure that
        // the test can be re-ran several times without failing.
        let externalfile = &format!("externalfile-{}", now.as_secs());
        let externalfile_client_path = &format!("{}/{}", external_client_path, externalfile);
        let externalfile_pulled_path = &format!("{}/{}", repo_path, externalfile);
        clone(remote_path, external_client_path);

        fs::write(&externalfile_client_path, "External content").expect("write file failed");
        let status = Command::new("git").arg("add")
                                        .arg(&externalfile)
                                        .current_dir(external_client_path)
                                        .status()
                                        .expect("command failed");
        assert!(status.success());

        let status = Command::new("git").arg("commit")
                                        .arg("-q")
                                        .arg("-m")
                                        .arg(format!("Adding {}", &externalfile))
                                        .current_dir(external_client_path)
                                        .status()
                                        .expect("command failed");
        assert!(status.success());

        let status = Command::new("git").arg("push")
                                        .arg("-q")
                                        .arg(GIT_REMOTE)
                                        .arg(GIT_BRANCH)
                                        .current_dir(external_client_path)
                                        .status()
                                        .expect("command failed");
        assert!(status.success());

        // Pull in external updates
        assert_ok(git_pull(repo_path));

        // Check that we got them
        let data = fs::read(&externalfile_pulled_path).expect("read file failed");
        assert_eq!(data, "External content".as_bytes());

        // Clean up external checkout
        rm_rf(external_client_path);
    }
}
