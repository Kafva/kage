use crate::age::age_try_lock;
use crate::age_error::AgeError;
use crate::util::path_to_filename;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::ptr::null;

use crate::*;

#[no_mangle]
pub extern "C" fn ffi_age_unlock_identity(
    encrypted_identity: *const c_char,
    passphrase: *const c_char,
) -> c_int {
    let Some(mut age_state) = age_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as c_int;
    };

    let encrypted_identity =
        unsafe { CStr::from_ptr(encrypted_identity).to_str() };
    let passphrase = unsafe { CStr::from_ptr(passphrase).to_str() };

    let (Ok(encrypted_identity), Ok(passphrase)) =
        (encrypted_identity, passphrase)
    else {
        age_state.last_error = Some(AgeError::GenericError);
        return -1;
    };

    match age_state.unlock_identity(encrypted_identity, passphrase) {
        Err(err) => {
            error!("{}", err);
            age_state.last_error = Some(err);
            -1
        }
        _ => 0,
    }
}

#[no_mangle]
pub extern "C" fn ffi_age_lock_identity() -> c_int {
    let Some(mut age_state) = age_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as c_int;
    };
    age_state.lock_identity();
    0
}

/// Encrypt `plaintext` for `recipient`, writing the ciphertext to `outpath`.
#[no_mangle]
pub extern "C" fn ffi_age_encrypt(
    plaintext: *const c_char,
    recipient: *const c_char,
    outpath: *const c_char,
) -> c_int {
    let Some(mut age_state) = age_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as c_int;
    };

    let plaintext = unsafe { CStr::from_ptr(plaintext).to_str() };
    let recipient = unsafe { CStr::from_ptr(recipient).to_str() };
    let outpath = unsafe { CStr::from_ptr(outpath).to_str() };

    let (Ok(plaintext), Ok(recipient), Ok(outpath)) =
        (plaintext, recipient, outpath)
    else {
        age_state.last_error = Some(AgeError::GenericError);
        return -1;
    };

    let Some(outfile) = path_to_filename(outpath) else {
        age_state.last_error = Some(AgeError::GenericError);
        return -1;
    };

    match age_state.encrypt(plaintext, recipient) {
        Ok(ciphertext) => match std::fs::write(outpath, &ciphertext) {
            Ok(_) => {
                debug!("Wrote {} byte(s) to '{}'", ciphertext.len(), outfile);
                return 0;
            }
            Err(err) => {
                error!("{}: {}", outfile, err);
                age_state.last_error = Some(AgeError::IoError(err))
            }
        },
        Err(err) => {
            error!("{}: {}", outfile, err);
            age_state.last_error = Some(err);
        }
    }
    -1
}

/// Returns the decrypted value for a given path, the returned pointer
/// must be passed back to rust and freed!
#[no_mangle]
pub extern "C" fn ffi_age_decrypt(
    encrypted_path: *const c_char,
) -> *const c_char {
    let Some(mut age_state) = age_try_lock() else {
        return null();
    };

    let encrypted_path = unsafe { CStr::from_ptr(encrypted_path).to_str() };

    let Ok(encrypted_path) = encrypted_path else {
        age_state.last_error = Some(AgeError::GenericError);
        return null();
    };

    let Some(filename) = path_to_filename(encrypted_path) else {
        age_state.last_error = Some(AgeError::GenericError);
        return null();
    };

    match std::fs::read(encrypted_path) {
        Ok(data) => match age_state.decrypt(data.as_slice()) {
            Ok(data) => {
                let Ok(s) = CString::new(data) else {
                    return null();
                };
                return s.into_raw();
            }
            Err(err) => {
                error!("{}: {}", filename, err);
                age_state.last_error = Some(err)
            }
        },
        Err(err) => {
            error!("{}: {}", filename, err);
            age_state.last_error = Some(AgeError::IoError(err))
        }
    }
    null()
}

/// Return a dynamically allocated string describing the last error that
/// occurred if any. The string must be passed back to rust and freed!
/// The internal `last_error` is cleared after being retrieved!
#[no_mangle]
pub extern "C" fn ffi_age_strerror() -> *const c_char {
    let Some(mut age_state) = age_try_lock() else {
        return std::ptr::null();
    };
    let Some(ref err) = age_state.last_error else {
        return std::ptr::null();
    };
    let Ok(s) = CString::new(err.to_string()) else {
        return std::ptr::null();
    };

    age_state.last_error = None;
    s.into_raw()
}
