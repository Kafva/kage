#[macro_export]
macro_rules! info {
    ($fmt:literal, $($x:expr),*) => {
        if cfg!(target = "aarch64-apple-ios-sim") {
            log!("\x1b[92mINFO\x1b[0m", $fmt, $($x),*);
        } else {
            log!("INFO", $fmt, $($x),*);
        }
    };
    ($level:literal, $msg:literal) => {
        log!("\x1b[92mINFO\x1b[0m", $msg)
    };
}

#[macro_export]
macro_rules! log {
    // Match level, format string and one or more expressions
    ($level:literal, $fmt:literal, $($x:expr),*) => {
        println!(concat!("\x1b[92m", $level, "\x1b[0m {}:{} ", $fmt),
                   file!(), line!(), $($x),*);
    };
    // Match level and string literal message
    ($level:literal, $msg:literal) => {
        println!(concat!("\x1b[92m", $level, "[\x1b[0m {}:{} {}"),
                   file!(), line!(), $msg);
    };
}

