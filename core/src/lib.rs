#[macro_use]
mod log;

mod ffi;

mod git;
mod git_ffi;
#[cfg(test)]
mod git_test;

mod age;
mod age_error;
mod age_ffi;
#[cfg(test)]
mod age_test;

#[cfg(target_os = "android")]
mod jni;
