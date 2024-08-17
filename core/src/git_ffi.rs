use std::ffi::c_void;
use crate::ffi::FFIArray;
use crate::ffi::KAGE_ERROR_LOCK_TAKEN;
use once_cell::sync::Lazy;
use std::ffi::CStr;
use std::ffi::CString;
use std::os::raw::{c_char, c_int};
use std::sync::Mutex;
use std::sync::MutexGuard;

use crate::git::*;
use crate::*;

/// Persistent library state for last error that occured
/// The git2::Error::last_error() method does not fit our needs, the error
/// message we want to show tends to be overwritten from later successful
/// invocations of git functions before we can retrieve it.
static GIT_LAST_ERROR: Lazy<Mutex<Option<git2::Error>>> =
    Lazy::new(|| Mutex::new(None));

macro_rules! ffi_git_call {
    ($result:expr, $last_error:ident) => {
        match $result {
            Ok(_) => 0,
            Err(err) => {
                error!("{}", err);
                *$last_error = Some(err);
                $last_error.as_ref().unwrap().raw_code() as c_int
            }
        }
    };
}

#[no_mangle]
pub extern "C" fn ffi_git_clone(
    url: *const c_char,
    into: *const c_char,
) -> c_int {
    let Some(mut git_last_error) = try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN;
    };
    git_setup();

    let url = unsafe { CStr::from_ptr(url).to_str() };
    let into = unsafe { CStr::from_ptr(into).to_str() };

    let (Ok(url), Ok(into)) = (url, into) else {
        return -1;
    };

    ffi_git_call!(git_clone(url, into), git_last_error)
}

#[no_mangle]
pub extern "C" fn ffi_git_pull(repo_path: *const c_char) -> c_int {
    let Some(mut git_last_error) = try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN;
    };
    git_setup();

    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };

    let Ok(repo_path) = repo_path else { return -1 };

    ffi_git_call!(git_pull(repo_path), git_last_error)
}

#[no_mangle]
pub extern "C" fn ffi_git_push(repo_path: *const c_char) -> c_int {
    let Some(mut git_last_error) = try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN;
    };
    git_setup();

    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };

    let Ok(repo_path) = repo_path else { return -1 };

    ffi_git_call!(git_push(repo_path), git_last_error)
}

/// Stage an 'add' or a 'rm' operation
#[no_mangle]
pub extern "C" fn ffi_git_stage(
    repo_path: *const c_char,
    relative_path: *const c_char,
) -> c_int {
    let Some(mut git_last_error) = try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN;
    };
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };
    let relative_path = unsafe { CStr::from_ptr(relative_path).to_str() };

    let (Ok(repo_path), Ok(relative_path)) = (repo_path, relative_path) else {
        return -1;
    };

    ffi_git_call!(git_stage(repo_path, relative_path), git_last_error)
}

#[no_mangle]
pub extern "C" fn ffi_git_reset(repo_path: *const c_char) -> c_int {
    let Some(mut git_last_error) = try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN;
    };
    git_setup();

    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };

    let Ok(repo_path) = repo_path else { return -1 };

    ffi_git_call!(git_reset(repo_path), git_last_error)
}

#[no_mangle]
pub extern "C" fn ffi_git_config_set_user(
    repo_path: *const c_char,
    username: *const c_char,
) -> c_int {
    let Some(mut git_last_error) = try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN;
    };
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };
    let username = unsafe { CStr::from_ptr(username).to_str() };

    let (Ok(repo_path), Ok(username)) = (repo_path, username) else {
        return -1;
    };

    ffi_git_call!(git_config_set_user(repo_path, username), git_last_error)
}

#[no_mangle]
pub extern "C" fn ffi_git_commit(
    repo_path: *const c_char,
    message: *const c_char,
) -> c_int {
    let Some(mut git_last_error) = try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN;
    };
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };
    let message = unsafe { CStr::from_ptr(message).to_str() };

    let (Ok(repo_path), Ok(message)) = (repo_path, message) else {
        return -1;
    };

    ffi_git_call!(git_commit(repo_path, message), git_last_error)
}

#[no_mangle]
pub extern "C" fn ffi_git_index_has_local_changes(
    repo_path: *const c_char,
) -> c_int {
    let Some(mut git_last_error) = try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN;
    };
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };

    let Ok(repo_path) = repo_path else { return -1 };

    match git_index_has_local_changes(repo_path) {
        Ok(has_changes) => has_changes as c_int,
        Err(err) => {
            error!("{}", err);
            *git_last_error = Some(err);
            git_last_error.as_ref().unwrap().raw_code() as c_int
        }
    }
}

/// Return a dynamically allocated string describing the last error that
/// occurred. The string must be passed back to rust and freed!
/// The internal `last_error` is cleared after being retrieved!
#[no_mangle]
pub extern "C" fn ffi_git_strerror() -> *const c_char {
    let Some(mut git_last_error) = try_lock() else {
        return std::ptr::null();
    };
    let Some(err) = git_last_error.as_ref() else {
        return std::ptr::null();
    };
    let Ok(s) = CString::new(err.message()) else {
        return std::ptr::null();
    };

    *git_last_error = None;
    s.into_raw()
}

/// Return an array of commit messages as "<timtestamp>\n<summary>" strings.
/// Each string must be passed back to rust and freed!
#[no_mangle]
pub extern "C" fn ffi_git_log(
    repo_path: *const c_char,
    outarr: *const *const c_char,
    outsize: c_int
) -> c_int {
    let Some(mut git_last_error) = try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN;
    };
    let repo_path = unsafe { CStr::from_ptr(repo_path).to_str() };

    let Ok(repo_path) = repo_path else {
        return -1
    };

    match git_log(repo_path) {
        Ok(arr) => {
            let arrlen = arr.len();
            if arrlen < outsize as usize {
                // let out_slice = unsafe {
                //     std::slice::from_raw_parts_mut(out, outsize as usize)
                // };
                // for i in 0..arrlen {
                //     out_slice[i] = data[i] as c_char
                // }
                // return arrlen as c_int;
            }
            warn!(
                "Output array to small: {} < {}", arrlen, outsize
            );
            0
        },
        Err(err) => {
            error!("{}", err);
            *git_last_error = Some(err);
            git_last_error.as_ref().unwrap().raw_code() as c_int
        }

    }
}


fn try_lock() -> Option<MutexGuard<'static, Option<git2::Error>>> {
    let Ok(git_last_error) = GIT_LAST_ERROR.try_lock() else {
        error!("Mutex lock already taken");
        return None;
    };
    Some(git_last_error)
}
