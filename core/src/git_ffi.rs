use std::ffi::CStr;
use std::os::raw::{c_char, c_int};

use crate::git::*;
use crate::*;

// Persistent library state
// static GIT_ERROR: Lazy<Mutex<git2::Error>> = Lazy::new(|| {
//     Mutex::new(git2::Error::last_error)
// });

macro_rules! ffi_git_call {
    ($result:expr) => {
        match $result {
            Ok(_) => 0,
            Err(err) => {
                error!("{}", err);
                err.raw_code() as c_int
            }
        }
    };
}

#[no_mangle]
pub extern "C" fn ffi_git_clone(
    url: *const c_char,
    into: *const c_char,
) -> c_int {
    let url = unsafe { CStr::from_ptr(url).to_str() };
    let into = unsafe { CStr::from_ptr(into).to_str() };

    let (Ok(url), Ok(into)) = (url, into) else {
        return -1;
    };

    ffi_git_call!(git_clone(url, into))
}

#[no_mangle]
pub extern "C" fn ffi_git_pull(repo_path: *const c_char) -> c_int {
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };

    let Ok(repo_path) = repo_path else { return -1 };

    ffi_git_call!(git_pull(repo_path))
}

#[no_mangle]
pub extern "C" fn ffi_git_push(repo_path: *const c_char) -> c_int {
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };

    let Ok(repo_path) = repo_path else { return -1 };

    ffi_git_call!(git_push(repo_path))
}

/// Stage an 'add' or a 'rm' operation
#[no_mangle]
pub extern "C" fn ffi_git_stage(
    repo_path: *const c_char,
    relative_path: *const c_char,
) -> c_int {
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };
    let relative_path = unsafe { CStr::from_ptr(relative_path).to_str() };

    let (Ok(repo_path), Ok(relative_path)) = (repo_path, relative_path) else {
        return -1;
    };

    ffi_git_call!(git_stage(repo_path, relative_path))
}

#[no_mangle]
pub extern "C" fn ffi_git_reset(repo_path: *const c_char) -> c_int {
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };

    let Ok(repo_path) = repo_path else { return -1 };

    ffi_git_call!(git_reset(repo_path))
}

#[no_mangle]
pub extern "C" fn ffi_git_config_set_user(
    repo_path: *const c_char,
    username: *const c_char,
) -> c_int {
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };
    let username = unsafe { CStr::from_ptr(username).to_str() };

    let (Ok(repo_path), Ok(username)) = (repo_path, username) else {
        return -1;
    };

    ffi_git_call!(git_config_set_user(repo_path, username))
}

#[no_mangle]
pub extern "C" fn ffi_git_commit(
    repo_path: *const c_char,
    message: *const c_char,
) -> c_int {
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };
    let message = unsafe { CStr::from_ptr(message).to_str() };

    let (Ok(repo_path), Ok(message)) = (repo_path, message) else {
        return -1;
    };

    ffi_git_call!(git_commit(repo_path, message))
}

#[no_mangle]
pub extern "C" fn ffi_git_index_has_local_changes(
    repo_path: *const c_char,
) -> c_int {
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };

    let Ok(repo_path) = repo_path else { return -1 };

    match git_index_has_local_changes(repo_path) {
        Ok(has_changes) => has_changes as c_int,
        Err(err) => {
            error!("{}", err);
            err.raw_code() as c_int
        }
    }
}

// #[no_mangle]
// pub extern "C"
// fn ffi_git_strerror() -> Vec<u8> {
//     err.message().as_bytes().to_vec()
// }
