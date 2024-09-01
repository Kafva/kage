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
