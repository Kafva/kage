use crate::{level_to_color,log_prefix,log,debug};

use std::path::Path;
use git2::{RemoteCallbacks,FetchOptions,Repository};
use git2::build::RepoBuilder;


#[macro_export]
macro_rules! concat_strs {
    ($li:expr)=> (
        $li.concat().as_str()
    )
}

// Git repo for each user is initialized server side with
// .age-recipients and .age-identities already present
// In iOS, we need to:
//  * Clone it
//  * Pull / Push
//  * conflict resolution...
//      - big error message and red button to delete local copy and re-clone

pub fn git_pull(repo_path: &str) -> i32 {
    0
}

pub fn git_push(repo_path: &str) -> i32 {
    0
}

pub fn git_add(repo_path: &str, path: &Path) -> Result<(), git2::Error> {
    let repo = Repository::open(repo_path)?;
    let mut index = repo.index()?;
    index.add_path(path)?;
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
    cb.transfer_progress(|stats| {
        let total = stats.total_objects();
        let indexed = stats.indexed_objects();
        let recv = stats.received_objects();
        let increments = total / 4;

        if recv == total && indexed == total {
            debug!("Cloning: Done");
        }
        else if recv % increments == 0 {
            debug!("Cloning: [{:4} / {:4}]", recv, total);
        }
        true
    });

    let mut fopts = FetchOptions::new();
    fopts.remote_callbacks(cb);

    RepoBuilder::new().fetch_options(fopts).clone(url, Path::new(into))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use crate::error;
    use std::fs::OpenOptions;
    use super::*;
    use std::fs;

    const CHECKOUT: &'static str =  "../git/kage-client/james";
    const NEWFILE: &'static str =  "newfile";

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

        touch(concat_strs!([CHECKOUT, "/", NEWFILE])).expect("touch failed");
        assert_ok(git_add(CHECKOUT, Path::new(NEWFILE)));

        assert_ok(git_commit(CHECKOUT, concat_strs!(["Adding ", NEWFILE])));
    }
}

