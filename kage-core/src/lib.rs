use std::ffi::{CStr,CString};
use std::os::raw::c_char;

// CString: an owned instance of a C-string
// CStr: a const reference to a C-string (immutable)

// no_mangle: Rust mangles function names by default, we need to disable this for
// ffi so that the public methods have predicatable names.

#[no_mangle]
pub extern "C" fn free_cstring(ptr: *mut c_char) {
    unsafe {
        if ptr.is_null() {
            return;
        }
        let cstr = CString::from_raw(ptr);
        drop(cstr)
    }
}

#[no_mangle]
pub extern "C" fn get_identity() -> *const c_char {
    let identity = gen_identity();
    let hello_str = CString::new(identity).expect("CString::new failed");
    hello_str.into_raw()
}

#[no_mangle]
pub extern "C" fn git_init(path: *const c_char) {
    unsafe {
        if let Ok(path) = CStr::from_ptr(path).to_str() {
            let _ = match git2::Repository::init(path) {
                Ok(_) => println!("ok init: {}", path),
                Err(e) => panic!("failed to init: {}", e),
            };
        }
    }
}

fn gen_identity() -> String {
    let key = age::x25519::Identity::generate();
    let pubkey = key.to_public();
    pubkey.to_string()
}

