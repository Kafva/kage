use std::ffi::{CStr,CString};
use std::os::raw::{c_char,c_int};

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

// Git api:
//
// * Create a git repo locally
// * Initalize a repo that points to it in ios
//  * pull from it
//  * commit to it
//  * push to it

// return status code
fn git_init(path: &str) -> c_int {
    match git2::Repository::init(path) {
        Ok(_) => {
            log!("INFO", "Created repo: {}", path);
            0
        },
        Err(e) => {
            log!("ERROR", "Failed to create repo: {}", e);
            e.raw_code()
        },
    }
}
