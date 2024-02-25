use std::ffi::{CStr,CString};
use std::os::raw::{c_char,c_int};

use crate::git::*;
use crate::age::*;

mod git;
mod age;

#[macro_use]
mod log;

// CString: an owned instance of a C-string
// CStr: a const reference to a C-string (immutable)

// no_mangle: Rust mangles function names by default, we need to disable this for
// ffi so that the public methods have predictable names.

macro_rules! ffi_git_call {
    ($result:expr) => (
        match $result {
            Ok(_) => 0,
            Err(err) => {
                error!("{}", err);
                err.raw_code() as c_int
            }
        }
    )
}

#[no_mangle]
pub extern "C" fn ffi_free_cstring(ptr: *mut c_char) {
    unsafe {
        if ptr.is_null() {
            return;
        }
        debug!("freeing ptr: {:#?}", ptr);
        let cstr = CString::from_raw(ptr);
        drop(cstr)
    }
}

#[no_mangle]
pub extern "C" fn ffi_git_clone(url: *const c_char,
                                into: *const c_char) -> c_int {
    unsafe {
        if let (Ok(url), Ok(into)) = (CStr::from_ptr(url).to_str(),
                                      CStr::from_ptr(into).to_str()) {
            return ffi_git_call!(git_clone(url, into))
        }
    }
    -1
}

#[no_mangle]
pub extern "C" fn ffi_git_pull(repo_path: *const c_char) -> c_int {
    unsafe {
        if let Ok(repo_path) = CStr::from_ptr(repo_path).to_str() {
            return ffi_git_call!(git_pull(repo_path))
        }
    }
    -1
}

#[no_mangle]
pub extern "C" fn ffi_git_push(repo_path: *const c_char) -> c_int {
    unsafe {
        if let Ok(repo_path) = CStr::from_ptr(repo_path).to_str() {
            return ffi_git_call!(git_push(repo_path))
        }
    }
    -1
}

#[no_mangle]
pub extern "C" fn ffi_git_add(repo_path: *const c_char,
                              path: *const c_char) -> c_int {
    unsafe {
        if let (Ok(repo_path), Ok(path)) = (CStr::from_ptr(repo_path).to_str(),
                                            CStr::from_ptr(path).to_str()) {
            return ffi_git_call!(git_add(repo_path, path))
        }
    }
    -1
}

#[no_mangle]
pub extern "C" fn ffi_git_commit(repo_path: *const c_char,
                                 message: *const c_char) -> c_int {
    unsafe {
        if let (Ok(repo_path), Ok(message)) = (CStr::from_ptr(repo_path).to_str(),
                                               CStr::from_ptr(message).to_str()) {
            return ffi_git_call!(git_commit(repo_path, message));
        }
    }
    -1
}

/// Encrypt `plaintext` for `recipient`, writing the ciphertext into `out`,
/// fails if the ciphertext exceeds the `outsize` and returns the bytes written.
#[no_mangle]
pub extern "C" fn ffi_age_encrypt(plaintext: *const c_char,
                                  recipient: *const c_char,
                                  out: *mut c_char,
                                  outsize: c_int) -> c_int {
    // TODO: limit unsafe blocks?
    unsafe {
        if let (Ok(plaintext), Ok(recipient)) = (CStr::from_ptr(plaintext).to_str(),
                                                 CStr::from_ptr(recipient).to_str()) {
            match age_encrypt(plaintext, recipient) {
                Ok(ciphertext) => {
                    let ciphersize = ciphertext.len();
                    if ciphersize < outsize as usize {
                        let out_slice = std::slice::from_raw_parts_mut(out, outsize as usize);
                        for i in 0..ciphersize {
                            out_slice[i] = ciphertext[i] as c_char
                        }
                        debug!("value: {}", out_slice[10]);
                        return ciphersize as c_int
                    }
                    warn!("Encryption output buffer to small: {} < {}", ciphersize, outsize);
                },
                Err(err) => {
                    error!("{:#?}", err);
                }
            }
        }
    }
    -1
}

// #[no_mangle]
// pub extern "C" fn ffi_age_decrypt_with_identity(ciphertext: *const c_char, 
//                                                 encrypted_identity: *const c_char, 
//                                                 passphrase: *const c_char) -> *const c_char {
//     // unsafe {
//     // }
//     std::ctr::null()
// }


