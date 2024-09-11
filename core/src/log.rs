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

/// The android logging backend is unsafe, the `_safe` version of the logging methods
/// should be used when logging inside of an already defined unsafe {} block.
#[cfg(not(target_os = "android"))]
#[macro_export]
macro_rules! debug_safe {
    ($($args:tt)*) => {
        log!("DEBUG", $($args)*)
    };
}

#[cfg(not(target_os = "android"))]
#[macro_export]
macro_rules! log_prefix {
    () => {
        "[kage-core] "
    };
}

#[cfg(not(target_os = "android"))]
#[macro_export]
macro_rules! log {
    // Match level, format string and arguments
    // The 'level' is matched as a token-tree to ensure that level_to_color!()
    // gets a literal as its argument.
    ($level:tt, $fmt:literal, $($x:expr),*) => {
        // Enable colored logs for all targets except real iOS devices
        // Pro-tip: rustc --print=cfg --target aarch64-apple-ios-sim
        if cfg!(all(target_os = "ios", not(target_abi = "sim"))) {
            println!(concat!(log_prefix!(), $level, " {}:{} ", $fmt),
                       file!(), line!(), $($x),*)
        } else {
            println!(concat!(log_prefix!(),
                             "\x1b[", level_to_color!($level), "m", $level,
                             "\x1b[0m {}:{} ", $fmt),
                     file!(), line!(), $($x),*)
        }
    };
    // Match level and string literal message
    ($level:tt, $msg:literal) => {
        if cfg!(all(target_os = "ios", not(target_abi = "sim"))) {
            println!(concat!(log_prefix!(), $level, " {}:{} {}"),
                       file!(), line!(), $msg);
        } else {
            println!(concat!(log_prefix!(),
                             "\x1b[", level_to_color!($level), "m", $level,
                             "\x1b[0m {}:{} ", $msg),
                     file!(), line!())
        }
    };
}
