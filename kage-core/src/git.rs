use crate::{level_to_color,log_prefix,log,debug};

use std::path::Path;
use git2::{RemoteCallbacks,FetchOptions,Repository};
use git2::build::RepoBuilder;

const GIT_REMOTE: &'static str = "origin";
const GIT_BRANCH: &'static str = "main";
const TRANSFER_STAGES: usize = 4;

pub fn git_pull(repo_path: &str) -> Result<(),git2::Error> {
    let repo = Repository::open(repo_path)?;
    let mut remote = repo.find_remote(GIT_REMOTE)?;

    let mut cb = git2::RemoteCallbacks::new();
    let mut fopts = git2::FetchOptions::new();

    cb.transfer_progress(|progress| transfer_progress(progress, "Fetch"));
    fopts.remote_callbacks(cb);

    remote.fetch(&[GIT_BRANCH], Some(&mut fopts), None)?;

    let fetch_head = repo.find_reference("FETCH_HEAD")?;
    let fetch_commit = repo.reference_to_annotated_commit(&fetch_head)?;

    let analysis = repo.merge_analysis(&[&fetch_commit])?;

    if analysis.0.is_up_to_date() {
        debug!("Already up to date.");
    }
    else if analysis.0.is_fast_forward() {
        debug!("Doing fast-forward merge");
        // let refname = format!("refs/heads/{}", GIT_BRANCH);
        // match repo.find_reference(&refname) {
        //     Ok(mut r) => {
        //         let name = match lb.name() {
        //             Some(s) => s.to_string(),
        //             None => String::from_utf8_lossy(lb.name_bytes()).to_string(),
        //         };
        //         let msg = format!("Fast-Forward: Setting {} to id: {}", name, rc.id());
        //         println!("{}", msg);
        //         lb.set_target(rc.id(), &msg)?;
        //         repo.set_head(&name)?;
        //         repo.checkout_head(Some(
        //             git2::build::CheckoutBuilder::default()
        //                 // For some reason the force is required to make the working directory actually get updated
        //                 // I suspect we should be adding some logic to handle dirty working directory states
        //                 // but this is just an example so maybe not.
        //                 .force(),
        //         ))?;
        //         Ok(())
        //     }
        //     Err(err) => { 
        //         return Err(err)
        //     }
        // };
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
    if total <= TRANSFER_STAGES {
        return true
    }

    let indexed = progress.indexed_objects();
    let recv = progress.received_objects();
    let increments = total / TRANSFER_STAGES;

    if recv == total && indexed == total {
        debug!("{}: Done", label);
    }
    else if recv % increments == 0 {
        debug!("{}: [{:4} / {:4}]", label, recv, total);
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::error;
    use std::fs::OpenOptions;
    use std::fs;

    const CHECKOUT: &'static str = "../git/kage-client/james";
    const NEWFILE: &'static str = "newfile";

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

    #[test]
    fn git_test() {
        // Remove previous checkout if needed
        if let Err(err) = fs::remove_dir_all(CHECKOUT) {
            match err.kind() {
                std::io::ErrorKind::NotFound => (),
                _ => panic!("{}", err)
            }
        }

        // Test clone -> add -> commit -> push
        assert_ok(git_clone("git://127.0.0.1/james", CHECKOUT));

        touch(format!("{}/{}", CHECKOUT, NEWFILE).as_str()).expect("touch failed");
        assert_ok(git_add(CHECKOUT, NEWFILE));

        assert_ok(git_commit(CHECKOUT, format!("Adding {}", NEWFILE).as_str()));

        assert_ok(git_push(CHECKOUT));

        assert_ok(git_pull(CHECKOUT));
    }
}
