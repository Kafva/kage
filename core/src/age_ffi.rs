use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int, c_ulonglong};
use std::sync::{Mutex, MutexGuard};
use std::time::SystemTime;

use once_cell::sync::Lazy;

use crate::age::AgeState;
use crate::*;

// Persistent library state
static AGE_STATE: Lazy<Mutex<AgeState>> =
    Lazy::new(|| Mutex::new(AgeState::default()));

#[no_mangle]
pub extern "C" fn ffi_age_unlock_identity(
    encrypted_identity: *const c_char,
    passphrase: *const c_char,
) -> c_int {
    let Some(mut age_state) = try_lock() else {
        return -1;
    };

    let encrypted_identity =
        unsafe { CStr::from_ptr(encrypted_identity).to_str() };
    let passphrase = unsafe { CStr::from_ptr(passphrase).to_str() };

    let (Ok(encrypted_identity), Ok(passphrase)) =
        (encrypted_identity, passphrase)
    else {
        return -1;
    };

    match age_state.unlock_identity(encrypted_identity, passphrase) {
        Err(err) => {
            error!("{}", err);
            age_state.last_error = Some(err);
            -1
        }
        _ => {
            // TODO: TMP
            age_state.last_error = Some(age_error::AgeError::NoIdentity);
            0
        }
    }
}

#[no_mangle]
pub extern "C" fn ffi_age_lock_identity() -> c_int {
    let Some(mut age_state) = try_lock() else {
        return -1;
    };
    age_state.lock_identity();
    0
}

#[no_mangle]
pub extern "C" fn ffi_age_unlock_timestamp() -> c_ulonglong {
    let Some(age_state) = try_lock() else {
        return 0;
    };
    let Some(timestamp) = age_state.unlock_timestamp else {
        return 0;
    };
    let Ok(duration) = timestamp.duration_since(SystemTime::UNIX_EPOCH) else {
        return 0;
    };

    duration.as_secs()
}

/// Encrypt `plaintext` for `recipient`, writing the ciphertext to `outpath`.
#[no_mangle]
pub extern "C" fn ffi_age_encrypt(
    plaintext: *const c_char,
    recipient: *const c_char,
    outpath: *const c_char,
) -> c_int {
    let Some(mut age_state) = try_lock() else {
        return -1;
    };

    let plaintext = unsafe { CStr::from_ptr(plaintext).to_str() };
    let recipient = unsafe { CStr::from_ptr(recipient).to_str() };
    let outpath = unsafe { CStr::from_ptr(outpath).to_str() };

    let (Ok(plaintext), Ok(recipient), Ok(outpath)) =
        (plaintext, recipient, outpath)
    else {
        return -1;
    };

    let Some(outfile) = path_to_filename(outpath) else {
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
            }
        },
        Err(err) => {
            error!("{}: {}", outfile, err);
            age_state.last_error = Some(err);
        }
    }
    -1
}

#[no_mangle]
pub extern "C" fn ffi_age_decrypt(
    encrypted_path: *const c_char,
    out: &mut c_char,
    outsize: c_int,
) -> c_int {
    let Some(mut age_state) = try_lock() else {
        return -1;
    };

    let encrypted_path = unsafe { CStr::from_ptr(encrypted_path).to_str() };

    let Ok(encrypted_path) = encrypted_path else {
        return -1;
    };

    let Some(filename) = path_to_filename(encrypted_path) else {
        return -1;
    };

    match std::fs::read(encrypted_path) {
        Ok(data) => match age_state.decrypt(data.as_slice()) {
            Ok(data) => {
                let datalen = data.len();
                if datalen < outsize as usize {
                    let out_slice = unsafe {
                        std::slice::from_raw_parts_mut(out, outsize as usize)
                    };
                    for i in 0..datalen {
                        out_slice[i] = data[i] as c_char
                    }
                    return datalen as c_int;
                }
                warn!(
                    "{}: Decryption output buffer to small: {} < {}",
                    filename, datalen, outsize
                );
            }
            Err(err) => {
                error!("{}: {}", filename, err);
                age_state.last_error = Some(err)
            }
        },
        Err(err) => {
            error!("{}: {}", filename, err);
        }
    }
    -1
}

// Return a dynamically allocated string describing the last error that
// occurred if any. The string must be passed back to rust and freed!
#[no_mangle]
pub extern "C" fn ffi_age_strerror() -> *const c_char {
    let Some(age_state) = try_lock() else {
        return std::ptr::null();
    };
    let Some(ref err) = age_state.last_error else {
        return std::ptr::null();
    };
    let Ok(s) = CString::new(err.to_string()) else {
        return std::ptr::null();
    };
    s.into_raw()
}

fn try_lock() -> Option<MutexGuard<'static, AgeState>> {
    let Ok(age_state) = AGE_STATE.try_lock() else {
        error!("Mutex lock already taken");
        return None;
    };
    Some(age_state)
}

fn path_to_filename(pathstr: &str) -> Option<&str> {
    let path = std::path::Path::new(pathstr);

    if let Some(filename) = path.file_name() {
        return filename.to_str();
    }

    error!("Bad filepath: '{}'", pathstr);
    None
}
