//! CString: an owned instance of a C-string
//! CStr: a const reference to a C-string (immutable)
//!
//! no_mangle: Rust mangles function names by default, we need to disable this for
//! ffi so that the public methods have predictable names.

use std::ffi::CStr;
use std::os::raw::{c_char,c_int};
use std::time::SystemTime;

use crate::git::*;
use crate::age::AgeState;
use std::sync::Mutex;

mod git;
mod age;
mod age_error;

#[macro_use]
mod log;

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

// static AGE_STATE: Mutex<AgeState> = Mutex::new(AgeState { identity: None, created: SystemTime::UNIX_EPOCH });

// fn path_to_filename(pathstr: &str) -> Option<&str> {
//     let path = std::path::Path::new(pathstr);

//     if let Some(filename) = path.file_name() {
//         return filename.to_str()
//     }

//     error!("Bad filepath: '{}'", pathstr);
//     None
// }

// #[no_mangle]
// pub extern "C" fn ffi_git_clone(url: *const c_char,
//                                 into: *const c_char) -> c_int {
//     unsafe {
//         if let (Ok(url), Ok(into)) = (CStr::from_ptr(url).to_str(),
//                                       CStr::from_ptr(into).to_str()) {
//             return ffi_git_call!(git_clone(url, into))
//         }
//     }
//     -1
// }

// #[no_mangle]
// pub extern "C" fn ffi_git_pull(repo_path: *const c_char) -> c_int {
//     unsafe {
//         if let Ok(repo_path) = CStr::from_ptr(repo_path).to_str() {
//             return ffi_git_call!(git_pull(repo_path))
//         }
//     }
//     -1
// }

// #[no_mangle]
// pub extern "C" fn ffi_git_push(repo_path: *const c_char) -> c_int {
//     unsafe {
//         if let Ok(repo_path) = CStr::from_ptr(repo_path).to_str() {
//             return ffi_git_call!(git_push(repo_path))
//         }
//     }
//     -1
// }

// #[no_mangle]
// pub extern "C" fn ffi_git_add(repo_path: *const c_char,
//                               path: *const c_char) -> c_int {
//     unsafe {
//         if let (Ok(repo_path), Ok(path)) = (CStr::from_ptr(repo_path).to_str(),
//                                             CStr::from_ptr(path).to_str()) {
//             return ffi_git_call!(git_add(repo_path, path))
//         }
//     }
//     -1
// }

// #[no_mangle]
// pub extern "C" fn ffi_git_commit(repo_path: *const c_char,
//                                  message: *const c_char) -> c_int {
//     unsafe {
//         if let (Ok(repo_path), Ok(message)) = (CStr::from_ptr(repo_path).to_str(),
//                                                CStr::from_ptr(message).to_str()) {
//             return ffi_git_call!(git_commit(repo_path, message));
//         }
//     }
//     -1
// }

// #[no_mangle]
// pub extern "C" fn ffi_age_unlock_identity(encrypted_identity: *const c_char,
//                                           passphrase: *const c_char) -> c_int {

//     let mut age_state = AGE_STATE.try_lock();
//     let encrypted_identity = unsafe { CStr::from_ptr(encrypted_identity).to_str() };
//     let passphrase = unsafe { CStr::from_ptr(passphrase).to_str() };

//     let (Ok(encrypted_identity), Ok(passphrase)) = (encrypted_identity, passphrase) else {
//         return -1
//     };

// }


// /// Encrypt `plaintext` for `recipient`, writing the ciphertext to outpath.
// #[no_mangle]
// pub extern "C" fn ffi_age_encrypt(plaintext: *const c_char,
//                                   recipient: *const c_char,
//                                   outpath: *const c_char) -> c_int {

//     let plaintext = unsafe { CStr::from_ptr(plaintext).to_str() };
//     let recipient = unsafe { CStr::from_ptr(recipient).to_str() };
//     let outpath = unsafe { CStr::from_ptr(outpath).to_str() };

//     let (Ok(plaintext),
//          Ok(recipient),
//          Ok(outpath)) = (plaintext, recipient, outpath) else {
//         return -1
//     };

//     let Some(outfile) = path_to_filename(outpath) else {
//         return -1
//     };

//     match age_encrypt(plaintext, recipient) {
//         Ok(ciphertext) => {
//            match std::fs::write(outpath, &ciphertext) {
//                Ok(_) => {
//                    debug!("Wrote {} byte(s) to '{}'", ciphertext.len(), outfile);
//                    return 0
//                },
//                Err(err) => {
//                    error!("{}: {}", outfile, err);
//                }
//            }
//         },
//         Err(err) => {
//             error!("{}: {}", outfile, err);
//         }
//     }
//     -1
// }

// #[no_mangle]
// pub extern "C" fn ffi_age_decrypt_with_identity(encrypted_path: *const c_char,
//                                                 encrypted_identity: *const c_char,
//                                                 passphrase: *const c_char,
//                                                 out: &mut c_char,
//                                                 outsize: c_int) -> c_int {

//     let encrypted_path = unsafe { CStr::from_ptr(encrypted_path).to_str() };
//     let encrypted_identity = unsafe { CStr::from_ptr(encrypted_identity).to_str() };
//     let passphrase = unsafe { CStr::from_ptr(passphrase).to_str() };

//     let (Ok(encrypted_path),
//          Ok(encrypted_identity),
//          Ok(passphrase)) = (encrypted_path, encrypted_identity, passphrase) else {
//         return -1
//     };

//     let Some(filename) = path_to_filename(encrypted_path) else {
//         return -1
//     };

//     match std::fs::read(encrypted_path) {
//         Ok(data) => {
//             match age_decrypt_with_identity(data.as_slice(),
//                                             encrypted_identity,
//                                             passphrase) {
//                 Ok(data) => {
//                     let datalen = data.len();
//                     if datalen < outsize as usize {
//                         let out_slice = unsafe {
//                             std::slice::from_raw_parts_mut(out, outsize as usize)
//                         };
//                         for i in 0..datalen {
//                             out_slice[i] = data[i] as c_char
//                         }
//                         return datalen as c_int
//                     }
//                     warn!("{}: decryption output buffer to small: {} < {}",
//                           filename, datalen, outsize);
//                 },
//                 Err(err) => {
//                     error!("{}: {}", filename, err);
//                 }
//             }
//         },
//         Err(err) => {
//             error!("{}: {}", filename, err);
//         }
//     }
//     -1
// }

