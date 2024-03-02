use std::path::Path;
use git2::{RemoteCallbacks,FetchOptions,Repository};
use git2::build::{CheckoutBuilder,RepoBuilder};

use crate::{level_to_color,log_prefix,log,debug};

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
    let remote_origin_head = repo.revparse_single(&format!("{}/{}", GIT_REMOTE, GIT_BRANCH))?.id();
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

pub fn git_add(repo_path: &str, path: &str) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    let mut index = repo.index()?;
    index.add_path(Path::new(path))?;
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
    let parent_commit = repo.find_commit(head.target().unwrap())?;

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

pub fn git_clone(url: &str, into: &str) -> Result<(), git2::Error> {
    let mut cb = RemoteCallbacks::new();
    cb.transfer_progress(|progress| transfer_progress(progress, "Cloning"));

    let mut fopts = FetchOptions::new();
    fopts.remote_callbacks(cb);

    RepoBuilder::new().fetch_options(fopts).clone(url, Path::new(into))?;
    Ok(())
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

    if recv == total && indexed == total && deltas == total_deltas {
        debug!("{}: Done", label);
    }

    true
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::error;
    use std::fs::OpenOptions;
    use std::fs;
    use std::process::Command;
    use std::time::{SystemTime, UNIX_EPOCH};

    const CHECKOUT: &'static str = "../git/kage-client/james";
    const EXTERNAL_CHECKOUT: &'static str = "/tmp/james";

    fn touch(path: &str) -> Result<fs::File, std::io::Error> {
        OpenOptions::new()
                    .write(true)
                    .create(true)
                    .open(path)
    }

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

    #[test]
    fn git_clone_test() {
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap();
        let newfile = format!("newfile-{}", now.as_secs());
        let externalfile = format!("externalfile-{}", now.as_secs());

        // Test: clone -> add -> commit -> push
        clone(CHECKOUT);

        touch(format!("{}/{}", CHECKOUT, newfile).as_str()).expect("touch failed");
        assert_ok(git_add(CHECKOUT, &newfile));

        assert_ok(git_commit(CHECKOUT, format!("Adding {}", newfile).as_str()));

        assert_ok(git_push(CHECKOUT));

        // Nothing to do
        assert_ok(git_pull(CHECKOUT));

        // Clone into a new location, add, commit and push from here
        clone(EXTERNAL_CHECKOUT);

        touch(format!("{}/{}", EXTERNAL_CHECKOUT, externalfile).as_str()).expect("touch failed");
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
        assert_ok(git_pull(CHECKOUT));
    }
}
