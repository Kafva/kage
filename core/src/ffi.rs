use std::ffi::c_int;
use std::ffi::CString;
use std::os::raw::c_char;

pub const KAGE_ERROR_LOCK_TAKEN: c_int = 111;

#[repr(C)]
pub struct CStringArray {
    pub ptr: *const *const c_char,
    pub len: c_int,
}

// #[no_mangle]
// pub extern "C" fn ffi_free_cstring_array(arr: CStringArray) {
//     if arr.ptr.is_null() {
//         return;
//     }
//     debug!("Freeing array at {:#?}", arr.ptr);
//     let s = unsafe { std::slice::from_raw_parts_mut(arr.ptr, arr.len as usize) };
//     let s = s.as_mut_ptr();
//     unsafe {
//         Box::from_raw(s);
//     }
// }

#[no_mangle]
pub extern "C" fn ffi_free_cstring(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    debug!("Freeing string at {:#?}", ptr);
    let cstr = unsafe { CString::from_raw(ptr) };
    drop(cstr)
}
