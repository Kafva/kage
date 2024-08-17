use std::ffi::c_int;
use std::ffi::CString;
use std::os::raw::c_char;

pub const KAGE_ERROR_LOCK_TAKEN: c_int = 111;

#[repr(C)]
pub struct FFIArray {
    arr: *const *const c_char,
    /// The length may be set to a negative value to indicate error
    len: c_int,
}

impl FFIArray {
    pub fn new(arr: *const *const c_char, len: c_int) -> Self {
        Self { arr, len }
    }
}

#[no_mangle]
pub extern "C" fn ffi_free_cstring(ptr: *mut c_char) {
    unsafe {
        if ptr.is_null() {
            return;
        }
        debug!("Freeing memory at {:#?}", ptr);
        let cstr = CString::from_raw(ptr);
        drop(cstr)
    }
}
