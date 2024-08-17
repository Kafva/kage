use std::ffi::c_int;
use std::ffi::CString;
use std::os::raw::c_char;

pub const KAGE_ERROR_LOCK_TAKEN: c_int = 111;

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
