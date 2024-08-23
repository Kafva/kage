use clap::Arg;
use std::io::{self, Write};

use kage_core::age::AgeState;
use kage_core::debug;
use kage_core::error;
use kage_core::level_to_color;
use kage_core::log;
use kage_core::log_prefix;

fn main() {
    let cmd = clap::Command::new("kage")
        .bin_name("kage")
        .arg(
            Arg::new("IDENTITY")
                .short('i')
                .long("identity")
                .help("Use the identity file at IDENTITY.")
                .required(true),
        )
        .arg(
            Arg::new("decrypt")
                .short('d')
                .long("decrypt")
                .help("Decrypt the input")
                .num_args(0),
        )
        .arg(
            Arg::new("INPUT")
                .help("Path to a file to read from.")
                .required(true)
                .index(1),
        );

    let matches = cmd.get_matches();

    let Some(inputfile) = matches.get_one::<String>("INPUT") else {
        return;
    };
    let Some(identity) = matches.get_one::<String>("IDENTITY") else {
        return;
    };
    let Some(decrypt) = matches.get_one::<bool>("decrypt") else {
        return;
    };

    debug!("input: {:#?}", inputfile);
    debug!("identity: {:#?}", identity);
    debug!("decrypt: {:#?}", decrypt);

    // Decrypt / encrypt the inputfile
    let mut age_state = AgeState {
        identity: None,
        unlock_timestamp: None,
        last_error: None,
    };

    let mut passphrase = String::new();

    print!("Enter passphrase for identity file \"{}\": ", inputfile);
    io::stdout().flush().unwrap();
    io::stdin()
        .read_line(&mut passphrase)
        .expect("Failed to read line");
    let passphrase = passphrase.trim();

    if let Err(e) = age_state.unlock_identity(inputfile, passphrase) {
        error!("{}", e);
        return;
    };
}
