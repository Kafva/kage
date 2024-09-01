#[macro_use]
mod log;

mod age;
mod age_error;
mod age_ffi;

mod git;
mod git_ffi;

mod ffi;

#[cfg(target_os = "android")]
mod jni;

#[cfg(test)]
mod age_test;

#[cfg(test)]
mod git_test;
