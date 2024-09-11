#[macro_use]
mod log;
#[cfg(target_os = "android")]
#[macro_use]
mod log_android;

mod util;

#[cfg(not(target_os = "android"))]
mod ffi;

// Age
mod age;
mod age_error;
#[cfg(not(target_os = "android"))]
mod age_ffi;
#[cfg(target_os = "android")]
mod age_jni;
#[cfg(test)]
mod age_test;

// Git
mod git;
#[cfg(not(target_os = "android"))]
mod git_ffi;
#[cfg(target_os = "android")]
mod git_jni;
#[cfg(test)]
mod git_test;

pub const KAGE_ERROR_LOCK_TAKEN: i32 = 111;
