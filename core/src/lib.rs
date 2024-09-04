use std::ffi::{c_int,c_char};

#[cfg(target_os = "android")]
//#[link(name = "log")]
extern "C" {
    pub fn __android_log_write(prio: c_int,
                               tag: *const c_char,
                               text: *const c_char)
                               -> c_int;
}

#[macro_use]
mod log;

mod age;
mod age_error;
mod git;

#[cfg(not(target_os = "android"))]
mod age_ffi;

#[cfg(not(target_os = "android"))]
mod git_ffi;

#[cfg(not(target_os = "android"))]
mod ffi;

#[cfg(target_os = "android")]
mod jni;

#[cfg(test)]
mod age_test;

#[cfg(test)]
mod git_test;

pub const KAGE_ERROR_LOCK_TAKEN: i32 = 111;
