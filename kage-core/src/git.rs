use std::path::Path;
use std::net::TcpStream;
use std::time::Duration;

use git2::{RemoteCallbacks,FetchOptions,Repository};
use git2::build::{CheckoutBuilder,RepoBuilder};

use crate::*;

const GIT_EMAIL: &'static str = env!("KAGE_GIT_EMAIL");
const GIT_REMOTE: &'static str = env!("KAGE_GIT_REMOTE");
const GIT_BRANCH: &'static str = env!("KAGE_GIT_BRANCH");
#[cfg(not(test))]
const GIT_CLONE_TIMEOUT: u64 = env!("KAGE_GIT_CLONE_TIMEOUT");

#[cfg(test)]
const GIT_CLONE_TIMEOUT: u64 = 1;

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
                 relative_path: &str) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    let mut index = repo.index()?;

    let cb = &mut |path: &Path, _matched_spec: &[u8]| -> i32 {
        let Some(path_str) = path.to_str() else {
            error!("Empty path encountered in '{}'", relative_path);
            return 1
        };

        let Ok(status) = repo.status_file(path) else {
            warn!("Unknown status: '{}'", path_str);
            return 1
        };

        match status {
            git2::Status::WT_MODIFIED =>  {
                debug!("Modified: '{}'", path_str);
                0
            },
            git2::Status::WT_NEW =>  {
                debug!("Added: '{}'", path_str);
                0
            },
            git2::Status::WT_DELETED =>  {
                debug!("Deleted: '{}'", path_str);
                0
            },
            git2::Status::WT_RENAMED =>  {
                debug!("Renamed: '{:?}'", path_str);
                0
            },
            _ => 1
        }
    };

    index.add_all(Some(relative_path), git2::IndexAddOption::DEFAULT, Some(cb))?;
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
    if let Err(err) = try_tcp_connect(url, Duration::from_secs(GIT_CLONE_TIMEOUT)) {
       error!("{}", err);
       return Err(err)
    };

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

fn try_tcp_connect(url: &str, timeout: Duration) -> Result<(), git2::Error> {
    let Some(address) = url.strip_prefix("git://") else {
        return Err(internal_error("Invalid protocol for remote address"))
    };

    let Some(spl) = address.split_once("/") else {
        return Err(internal_error("Error parsing remote address"))
    };

    // Fallback to default git daemon port
    let address: String;
    let colon_count = spl.0.chars().filter( |c| { *c == ':' }).count();

    if colon_count == 0 {
        address = spl.0.to_string() + ":9418";
    }
    else if colon_count == 1 {
        address = spl.0.to_string()
    }
    else {
        return Err(internal_error("Error parsing remote address"))
    }

    let Ok(sockaddr) = address.parse() else {
        return Err(internal_error("Error parsing remote address"))
    };

    match TcpStream::connect_timeout(&sockaddr, timeout) {
        Ok(_) => {
            Ok(())
        }
        Err(err) => {
            let msg = &format!("Error connecting to remote address: {}", err);
            Err(internal_error(msg))
        }
    }
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

    const GIT_USERNAME: &'static str = env!("KAGE_TEST_GIT_USERNAME");
    const GIT_REMOTE_CLONE_URL: &'static str = env!("KAGE_TEST_GIT_REMOTE_CLONE_URL");
    const GIT_CLIENT_DIR: &'static str = env!("KAGE_TEST_GIT_CLIENT_DIR");

    fn assert_ok(result: Result<(), git2::Error>) {
        if let Some(err) = result.as_ref().err() {
            error!("{}", err);
        }
        assert!(result.is_ok())
    }

    fn assert_err(result: Result<(), git2::Error>) {
        if let Some(_) = result.as_ref().ok() {
            error!("Unexpected successful result");
        }
        assert!(result.is_err())
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

    fn current_time() -> u64 {
        use std::time::{SystemTime, UNIX_EPOCH};
        SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs()
    }

    fn external_push_file(repo_path: &str, filepath: &str) {
        let status = Command::new("git").arg("add")
                                        .arg(&filepath)
                                        .current_dir(repo_path)
                                        .status()
                                        .expect("command failed");
        assert!(status.success());

        let status = Command::new("git").arg("commit")
                                        .arg("-q")
                                        .arg("-m")
                                        .arg(format!("Adding {}", &filepath))
                                        .current_dir(repo_path)
                                        .status()
                                        .expect("command failed");
        assert!(status.success());

        let status = Command::new("git").arg("push")
                                        .arg("-q")
                                        .arg(GIT_REMOTE)
                                        .arg(GIT_BRANCH)
                                        .current_dir(repo_path)
                                        .status()
                                        .expect("command failed");
        assert!(status.success());
    }

    #[test]
    /// Test we get expected errors when trying to:
    ///   1. Push to a remote that has external changes
    ///   2. Pull from a remote that has conflicting changes
    fn git_conflict_test() {
        let remote_path = &format!("{}/conflict_test", GIT_REMOTE_CLONE_URL);
        let repo_path = &format!("{}/conflict_test", GIT_CLIENT_DIR);
        let now = current_time();
        let external_client_path = &format!("/tmp/.pull_test-{}", now);

        let file = "conflict_file";
        let file_external_client_path = &format!("{}/{}", external_client_path, file);
        let file_our_path = &format!("{}/{}", repo_path, file);

        // Clone into two locations
        clone(remote_path, repo_path);
        clone(remote_path, external_client_path);

        // Create conflicting commits in each checkout
        fs::write(&file_our_path, "My content").expect("write file failed");
        assert_ok(git_stage(repo_path, &file));
        assert_ok(git_commit(repo_path, "My commit"));

        fs::write(&file_external_client_path, "External content").expect("write file failed");
        external_push_file(external_client_path, file);

        // Try to push/pull after the external update has occured
        assert_err(git_push(repo_path));
        assert_err(git_pull(repo_path));

        // Clean up external checkout
        rm_rf(external_client_path);
    }

    #[test]
    /// Test that a clone operation times out when the remote host is unreachable
    fn git_clone_bad_host_test() {
        let repo_path = &format!("{}/bad_remote", GIT_CLIENT_DIR);

        // Unsupported protocol
        rm_rf(repo_path);
        assert_err(git_clone("https://127.0.0.1/bad_host", repo_path));

        // Unreachable host, with port
        rm_rf(repo_path);
        assert_err(git_clone("git://169.254.111.111:9988/bad_host", repo_path));

        // Unreachable host, no port
        rm_rf(repo_path);
        assert_err(git_clone("git://169.254.111.111/bad_host", repo_path));
    }

    #[test]
    /// Test that we can stage a 'remove folder' and a 'add file' operation
    /// in the same commit.
    fn git_stage_test() {
        let remote_path = &format!("{}/stage_test", GIT_REMOTE_CLONE_URL);
        let repo_path = &format!("{}/stage_test", GIT_CLIENT_DIR);

        let folder1 = &format!("folder1-{}", current_time());
        let folder2 = &format!("folder2-{}", current_time());
        let file1 = "file1";
        let file2 = "file2";
        let file3 = "file3";
        let file4 = "file4";

        let folder1_path = format!("{}/{}", repo_path, folder1);
        let folder2_path = format!("{}/{}", folder1_path, folder2);
        let file1_path = format!("{}/{}", folder1_path, file1);
        let file2_path = format!("{}/{}", folder1_path, file2);
        let file3_path = format!("{}/{}", folder2_path, file3);
        let file4_path = format!("{}/{}", folder1_path, file4);

        clone(remote_path, repo_path);

        fs::create_dir(&folder1_path).expect("create directory failed");
        fs::create_dir(&folder2_path).expect("create directory failed");
        fs::write(&file1_path, "First").expect("write file failed");
        fs::write(&file2_path, "Second").expect("write file failed");
        fs::write(&file3_path, "Third").expect("write file failed");

        // Commit all of folder1
        assert_ok(git_stage(repo_path, &folder1));
        assert_ok(git_commit(repo_path, &format!("Add '{}'", folder1)));
        assert_ok(git_push(repo_path));

        // Remove subfolder (folder2) and create a new file under folder1
        rm_rf(&folder2_path);
        fs::write(&file4_path, "Fourth").expect("write file failed");

        assert_ok(git_stage(repo_path, &folder1));
        assert_ok(git_commit(repo_path, &format!("Remove '{}' and add '{}'", folder2, file4)));
        assert_ok(git_push(repo_path));

        // Remove folder1
        rm_rf(&folder1_path);

        assert_ok(git_stage(repo_path, &folder1));
        assert_ok(git_commit(repo_path, &format!("Remove '{}'", folder1)));
        assert_ok(git_push(repo_path));
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
        assert_ok(git_stage(repo_path, &file_to_keep));
        assert_ok(git_stage(repo_path, &file_to_remove));
        assert_ok(git_stage(repo_path, &file_to_modify));
        assert_ok(git_commit(repo_path, "Test commit"));
        assert_ok(git_push(repo_path));

        // Stage some changes to them and commit
        fs::remove_file(&file_to_remove_path).expect("remove file failed");
        fs::write(&file_to_modify_path, "Different content").expect("write file failed");

        assert_ok(git_stage(repo_path, &file_to_remove));
        assert_ok(git_stage(repo_path, &file_to_modify));
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

        // Create a commit
        fs::write(&file_to_keep_path, "To keep").expect("write file failed");
        assert_ok(git_stage(repo_path, &file_to_keep));
        assert_ok(git_commit(repo_path, "Test commit"));
        assert_ok(git_push(repo_path));

        // Nothing to do
        assert_ok(git_pull(repo_path));

        // Clone into a new location, add, commit and push from here
        let now = current_time();
        let external_client_path = &format!("/tmp/.pull_test-{}", now);
        // Use the current time as a suffix for the new file to ensure that
        // the test can be re-ran several times without failing.
        let externalfile = &format!("externalfile-{}", now);
        let externalfile_client_path = &format!("{}/{}", external_client_path, externalfile);
        let externalfile_pulled_path = &format!("{}/{}", repo_path, externalfile);
        clone(remote_path, external_client_path);

        fs::write(&externalfile_client_path, "External content").expect("write file failed");
        external_push_file(externalfile_client_path, externalfile);

        // Pull in external updates
        assert_ok(git_pull(repo_path));

        // Check that we got them
        let data = fs::read(&externalfile_pulled_path).expect("read file failed");
        assert_eq!(data, "External content".as_bytes());

        // Clean up external checkout
        rm_rf(external_client_path);
    }
}
