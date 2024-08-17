use std::ffi::{CStr, CString};
use std::os::raw::c_char;

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
