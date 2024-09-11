use std::ffi::{c_char, c_int};

extern "C" {
    pub fn __android_log_write(
        prio: c_int,
        tag: *const c_char,
        text: *const c_char,
    ) -> c_int;
}

#[macro_export]
macro_rules! android_level_to_prio {
    ("DEBUG") => {
        3 as std::ffi::c_int
    };
    ("INFO") => {
        4 as std::ffi::c_int
    };
    ("WARN") => {
        5 as std::ffi::c_int
    };
    ("ERROR") => {
        6 as std::ffi::c_int
    };
}

#[macro_export]
macro_rules! android_tag {
    () => {
        "kafva.kage\0"
    };
}

#[macro_export]
macro_rules! debug_safe {
    ($($args:tt)*) => {
        // Do not include debug output in release builds
        #[cfg(feature = "debug_logs")]
        log_safe!("DEBUG", $($args)*)
    };
}

#[macro_export]
macro_rules! log_safe {
    ($level:tt, $fmt:literal, $($x:expr),*) => {
        {
            let msg = format!(concat!("{}:{} ", $fmt, "\0"), file!(), line!(), $($x),*);
            crate::log_android::__android_log_write(
                android_level_to_prio!($level),
                android_tag!().as_ptr() as *const std::ffi::c_char,
                msg.as_ptr() as *const std::ffi::c_char,
            );
        }
    };
    ($level:tt, $msg:literal) => {
        crate::log_android::__android_log_write(
            android_level_to_prio!($level),
            android_tag!().as_ptr() as *const std::ffi::c_char,
            format!("{}\0", $msg).as_ptr() as *const std::ffi::c_char,
        );
    };
}

#[macro_export]
macro_rules! log {
    ($level:tt, $fmt:literal, $($x:expr),*) => {
        unsafe {
            log_safe!($level, $fmt, $($x),*);
        };
    };
    ($level:tt, $msg:literal) => {
        unsafe {
            log_safe!($level, $msg);
        };
    };
}
