use std::ffi::c_int;
use std::ffi::CString;
use std::os::raw::c_char;

#[repr(C)]
pub struct CStringArray {
    pub ptr: *const *const c_char,
    pub len: c_int,
}

#[no_mangle]
pub extern "C" fn ffi_free_cstring(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    debug!("Freeing string at {:#?}", ptr);
    let cstr = unsafe { CString::from_raw(ptr) };
    drop(cstr)
}
