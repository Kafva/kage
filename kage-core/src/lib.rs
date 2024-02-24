use std::ffi::{CStr,CString};
use std::os::raw::{c_char,c_int};

use crate::git::*;

mod git;

#[macro_use]
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
            match git_clone(url, into) {
                Ok(_) => 0,
                Err(err) => {
                    error!("{}", err);
                    err.raw_code() as c_int
                }
            };
        }
        -1
    }
}

#[no_mangle]
pub extern "C" fn ffi_git_pull(repo_path: *const c_char) -> c_int {
    unsafe {
        if let Ok(repo_path) = CStr::from_ptr(repo_path).to_str() {
            return git_pull(repo_path);
        }
        -1
    }
}

#[no_mangle]
pub extern "C" fn ffi_git_push(repo_path: *const c_char) -> c_int {
    unsafe {
        if let Ok(repo_path) = CStr::from_ptr(repo_path).to_str() {
            return git_push(repo_path);
        }
        -1
    }
}

#[no_mangle]
pub extern "C" fn ffi_git_commit(repo_path: *const c_char, message: *const c_char) -> c_int {
    unsafe {
        if let (Ok(repo_path), Ok(message)) = (CStr::from_ptr(repo_path).to_str(),
                                               CStr::from_ptr(message).to_str()) {
            match git_commit(repo_path, message) {
                Ok(_) => 0,
                Err(err) => {
                    error!("{}", err);
                    err.raw_code() as c_int
                }
            };
        }
        -1
    }
}
