use super::*;
use crate::error;
use crate::git::*;
use std::fs;
use std::process::Command;

const GIT_USERNAME: &'static str = env!("KAGE_TEST_GIT_REPONAME");
const GIT_REMOTE_CLONE_URL: &'static str =
    env!("KAGE_TEST_GIT_REMOTE_CLONE_URL");
const GIT_CLIENT_DIR: &'static str = env!("KAGE_TEST_GIT_CLIENT_DIR");

// Test cases:
//      * Add and commit
//      * Change existing and commit
//      * Remove and commit
//      * Reset to remote head
//
//  Error cases:
//      * Pull with conflict
//      * Clone with bad host

#[test]
/// Test we get expected errors when trying to:
///   1. Push to a remote that has external changes
///   2. Pull from a remote that has conflicting changes
fn git_conflict_test() {
    let remote_path = &format!("{}/conflict_test", GIT_REMOTE_CLONE_URL);
    let repo_path = &format!("{}/conflict_test", GIT_CLIENT_DIR);
    let now = current_time();
    let external_client_path = &format!("/tmp/.conflict_test-{}", now);

    let file = &format!("conflict_file-{}", now);
    let file_external_client_path =
        &format!("{}/{}", external_client_path, file);
    let file_our_path = &format!("{}/{}", repo_path, file);

    // Clone into two locations
    clone(remote_path, repo_path);
    clone(remote_path, external_client_path);

    // Create conflicting commits in each checkout
    fs::write(&file_our_path, "My content").expect("write file failed");
    assert_ok(git_stage(repo_path, &file));
    assert_ok(git_commit(repo_path, "My commit"));

    fs::write(&file_external_client_path, "External content")
        .expect("write file failed");
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
    let now = current_time();

    let folder1 = &format!("folder1-{}", now);
    let folder2 = &format!("folder2-{}", now);
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
    assert_ok(git_commit(
        repo_path,
        &format!("Remove '{}' and add '{}'", folder2, file4),
    ));
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
    fs::write(&file_to_modify_path, "Different content")
        .expect("write file failed");

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
    let now = current_time();

    let file_to_keep = &format!("our_file-{}", now);
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
    let external_client_path = &format!("/tmp/.pull_test-{}", now);
    // Use the current time as a suffix for the new file to ensure that
    // the test can be re-ran several times without failing.
    let externalfile = &format!("externalfile-{}", now);
    let externalfile_client_path =
        &format!("{}/{}", external_client_path, externalfile);
    let externalfile_pulled_path = &format!("{}/{}", repo_path, externalfile);
    clone(remote_path, external_client_path);

    fs::write(&externalfile_client_path, "External content")
        .expect("write file failed");
    external_push_file(external_client_path, externalfile);

    // Pull in external updates
    assert_ok(git_pull(repo_path));

    // Check that we got them
    let data = fs::read(&externalfile_pulled_path).expect("read file failed");
    assert_eq!(data, "External content".as_bytes());

    // Clean up external checkout
    rm_rf(external_client_path);
}

////////////////////////////////////////////////////////////////////////////////

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
        return;
    };

    match err.kind() {
        std::io::ErrorKind::NotFound => (),
        _ => panic!("{}", err),
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
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs()
}

fn external_push_file(repo_path: &str, filepath: &str) {
    let status = Command::new("git")
        .arg("add")
        .arg(&filepath)
        .current_dir(repo_path)
        .status()
        .expect("command failed");
    assert!(status.success());

    let status = Command::new("git")
        .arg("commit")
        .arg("-q")
        .arg("-m")
        .arg(format!("Adding {}", &filepath))
        .current_dir(repo_path)
        .status()
        .expect("command failed");
    assert!(status.success());

    let status = Command::new("git")
        .arg("push")
        .arg("-q")
        .arg(GIT_REMOTE)
        .arg(GIT_BRANCH)
        .current_dir(repo_path)
        .status()
        .expect("command failed");
    assert!(status.success());
}
