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

