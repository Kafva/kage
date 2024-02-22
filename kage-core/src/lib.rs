use std::path::Path;
use std::ffi::{CStr,CString};
use std::os::raw::{c_char,c_int};

use git2::{RemoteCallbacks,FetchOptions};
use git2::build::RepoBuilder;

mod log;

// CString: an owned instance of a C-string
// CStr: a const reference to a C-string (immutable)

// no_mangle: Rust mangles function names by default, we need to disable this for
// ffi so that the public methods have predicatable names.

#[no_mangle]
pub extern "C" fn ffi_free_cstring(ptr: *mut c_char) {
    unsafe {
        if ptr.is_null() {
            return;
        }
        let cstr = CString::from_raw(ptr);
        drop(cstr)
    }
}


#[no_mangle]
pub extern "C" fn ffi_git_clone(url: *const c_char, into: *const c_char) -> c_int {
    unsafe {
        if let (Ok(url), Ok(into)) = (CStr::from_ptr(url).to_str(), 
                                      CStr::from_ptr(into).to_str()) {
            return git_clone(url, into)
        }
        -1
    }
}

#[no_mangle]
pub extern "C" fn ffi_git_pull(repo_path: *const c_char) -> c_int {
    unsafe {
        0
    }
}

#[no_mangle]
pub extern "C" fn ffi_git_push(repo_path: *const c_char) -> c_int {
    unsafe {
        0
    }
}

// Git repo for each user is initialized server side with
// .age-recipients and .age-identities already present
// In iOS, we need to:
//  * Clone it
//  * Pull / Push
//  * conflict resolution...
//      - big error message and red button to delete local copy and re-clone

fn git_clone(url: &str, into: &str) -> c_int {
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

    match RepoBuilder::new().fetch_options(fopts).clone(url, Path::new(into)) {
        Ok(_) => 0,
        Err(err) => {
            error!("Clone failed: {}", err);
            -1
        }
    }
}

#[test]
fn git_clone_test() {
    use std::fs;
    let checkout = "/tmp/james_clone";

    // Remove previous checkout if needed
    if let Err(err) = fs::remove_dir_all(checkout) {
        match err.kind() {
            std::io::ErrorKind::NotFound => (),
            _ => panic!("{}", err)
        }
    }

    assert_eq!(git_clone("git://10.0.2.7/james", checkout), 0);
    assert_eq!(git_clone("git://10.0.2.7/invalid", "/tmp/invalid"), -1);
}
