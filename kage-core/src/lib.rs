use std::ffi::CString;

#[no_mangle]
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[no_mangle]
pub extern "C" fn get_cstring() -> *const i8 {
    let hello_str = CString::new("Hello from Rust!").expect("CString::new failed");
    hello_str.into_raw()
}

#[no_mangle]
pub extern "C" fn free_cstring(ptr: *mut i8) {
    unsafe {
        if ptr.is_null() {
            return;
        }
        let _ = CString::from_raw(ptr);
    }
}

#[no_mangle]
pub extern "C" fn get_identity() -> *const i8 {
    let identity = gen_identity();
    let hello_str = CString::new(identity).expect("CString::new failed");
    hello_str.into_raw()
}

#[no_mangle]
pub extern "C" fn git_init(path: *const i8) {
    let path = CString::new(path).expect("CString::new failed");
    let _ = match git2::Repository::init("./ffi") {
        Ok(repo) => repo,
        Err(e) => panic!("failed to init: {}", e),
    }; 
}


fn gen_identity() -> String {
    let key = age::x25519::Identity::generate();
    let pubkey = key.to_public();
    pubkey.to_string()
}

