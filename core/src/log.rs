#[macro_export]
macro_rules! log_prefix {
    () => {
        "[kage-core] "
    };
}

#[macro_export]
macro_rules! level_to_color {
    ("DEBUG") => {
        "94"
    };
    ("INFO") => {
        "92"
    };
    ("WARN") => {
        "93"
    };
    ("ERROR") => {
        "91"
    };
}

#[cfg(target_os = "android")]
#[macro_export]
macro_rules! android_level_to_prio {
    ("DEBUG") => {
        android_log_sys::LogPriority::DEBUG as std::ffi::c_int
    };
    ("INFO") => {
        android_log_sys::LogPriority::INFO as std::ffi::c_int
    };
    ("WARN") => {
        android_log_sys::LogPriority::WARN as std::ffi::c_int
    };
    ("ERROR") => {
        android_log_sys::LogPriority::ERROR as std::ffi::c_int
    };
}

#[cfg(target_os = "android")]
#[macro_export]
macro_rules! android_tag {
    () => {
        "kafva.kage\0"
    };
}

#[macro_export]
macro_rules! debug {
    ($($args:tt)*) => {
        // Do not include debug output in release builds
        #[cfg(feature = "debug_logs")]
        log!("DEBUG", $($args)*)
    };
}

#[macro_export]
macro_rules! info {
    ($($args:tt)*) => {
        log!("INFO", $($args)*)
    };
}

#[macro_export]
macro_rules! warn {
    ($($args:tt)*) => {
        log!("WARN", $($args)*)
    };
}

#[macro_export]
macro_rules! error {
    ($($args:tt)*) => {
        log!("ERROR", $($args)*)
    };
}

// Do not color logs when building for a real iOS target
#[macro_export]
macro_rules! log {
    // Match level, format string and arguments
    // The 'level' is matched as a token-tree to ensure that level_to_color!()
    // gets a literal as its argument.
    ($level:tt, $fmt:literal, $($x:expr),*) => {
        if cfg!(target_os = "android") {
            let msg = format!(concat!("{}:{} ", $fmt, "\0"), file!(), line!(), $($x),*);
            unsafe {
                android_log_sys::__android_log_write(
                    android_level_to_prio!($level),
                    android_tag!().as_ptr() as *const std::ffi::c_char,
                    msg.as_ptr() as *const std::ffi::c_char,
                );
            };
        }
        else if cfg!(feature = "color_logs") {
            println!(concat!(log_prefix!(),
                             "\x1b[", level_to_color!($level), "m", $level,
                             "\x1b[0m {}:{} ", $fmt),
                     file!(), line!(), $($x),*)
        } else {
            println!(concat!(log_prefix!(), $level, " {}:{} ", $fmt),
                       file!(), line!(), $($x),*)
        }
    };
    // Match level and string literal message
    ($level:tt, $msg:literal) => {
        if cfg!(target_os = "android") {
            unsafe {
                android_log_sys::__android_log_write(
                    android_level_to_prio!($level),
                    android_tag!().as_ptr() as *const std::ffi::c_char,
                    format!("{}\0", $msg).as_ptr() as *const std::ffi::c_char,
                );
            };
        }
        else if cfg!(feature = "color_logs") {
            println!(concat!(log_prefix!(),
                             "\x1b[", level_to_color!($level), "m", $level,
                             "\x1b[0m {}:{} ", $msg),
                     file!(), line!())
        } else {
            println!(concat!(log_prefix!(), $level, " {}:{} {}"),
                       file!(), line!(), $msg);
        }
    };
}
