#[macro_use]
mod log;

// Needs to be public for kage CLI
pub mod age;
mod age_error;

#[cfg(any(test, target_os = "android", target_os = "ios"))]
mod git;

#[cfg(test)]
mod age_test;

#[cfg(test)]
mod git_test;

#[cfg(any(target_os = "android", target_os = "ios"))]
mod age_ffi;
#[cfg(any(target_os = "android", target_os = "ios"))]
mod ffi;
#[cfg(any(target_os = "android", target_os = "ios"))]
mod git_ffi;

#[cfg(target_os = "android")]
mod jni;
