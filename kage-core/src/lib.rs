use std::ffi::{CStr,CString};
use std::os::raw::{c_char,c_int};

use git2::{Repository,RepositoryInitOptions};

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
pub extern "C" fn ffi_git_init(path: *const c_char) -> c_int {
    unsafe {
        if let Ok(path) = CStr::from_ptr(path).to_str() {
            return git_init(path)
        }
        -1
    }

}

// Git repo for each user is initialized server side with
// .age-recipients and .age-identities already present
// In iOS, we need to:
//  * Clone it
//  * Pull / Push
//  * conflict resolution...
//      - big error message and red button to delete local copy and re-clone

// return status code
fn git_init(path: &str) -> c_int {
    // TODO clone
    let init_opts = RepositoryInitOptions::new();
    // Some("git://10.0.2.7/james");

    match Repository::init_opts(path, &init_opts) {
        Ok(_) => {
            info!("Created repo: {}", path);
            0
        },
        Err(e) => {
            info!("Failed to create repo: {}", e);
            e.raw_code()
        },
    }
}


#[test]
fn git_clone_test() {

}
