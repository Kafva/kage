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

#[macro_export]
macro_rules! debug {
    ($($args:tt)*) => {
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
        if cfg!(not(feature = "simulator")) {
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
        if cfg!(not(feature = "simulator")) {
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
