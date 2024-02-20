#[macro_export]
macro_rules! level_to_color {
    ("DEBUG") => { "94" };
    ("INFO") => { "92" };
    ("WARN") => { "93" };
    ("ERROR") => { "91" };
}


#[macro_export]
macro_rules! info {
    ($fmt:literal, $($x:expr),*) => {
        log!("INFO", $fmt, $($x),*);
    };
    ($msg:literal) => {
        log!("INFO", $msg);
    };
}

// Do not color logs when building for a real iOS target
#[macro_export]
macro_rules! log {
    // Match level, format string and arguments
    // The 'level' is matched as a token-tree to ensure that level_to_color!()
    // gets a literal as its argument.
    ($level:tt, $fmt:literal, $($x:expr),*) => {
        if cfg!(target = "aarch64-apple-ios") {
            println!(concat!($level, " {}:{} ", $fmt),
                       file!(), line!(), $($x),*);
        } else {
            println!(concat!("\x1b[", level_to_color!($level), "m", $level, "\x1b[0m {}:{} ", $fmt),
                       file!(), line!(), $($x),*);
        }
    };
    // Match level and string literal message 
    ($level:tt, $msg:literal) => {
        if cfg!(target = "aarch64-apple-ios") {
            println!(concat!($level, " {}:{} {}"),
                       file!(), line!(), $msg);
        } else {
            println!(concat!("\x1b[", level_to_color!($level), "m", $level, "\x1b[0m {}:{} ", $msg),
                       file!(), line!());
        }
    };

}

