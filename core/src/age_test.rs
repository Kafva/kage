use crate::age::AgeState;
use crate::age_error::AgeError;
use crate::error;

use age;
use age::secrecy::Secret;

const PLAINTEXT: &str = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
const PASSPHRASE: &str = "pass: !#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

/// Encrypt and decrypt with a pair of x25519 keys
#[test]
fn age_key_test() {
    let identity = age::x25519::Identity::generate();
    let pubkey = identity.to_public();
    let state = AgeState {
        identity: Some(identity),
        last_error: None,
    };

    let ciphertext = state.encrypt(PLAINTEXT, pubkey.to_string().as_str());
    assert_ok(&ciphertext);

    let decrypted = state.decrypt(&ciphertext.unwrap());

    assert_ok(&decrypted);
    assert_eq!(decrypted.unwrap(), PLAINTEXT.as_bytes());
}

/// Encrypt a private key with a passphrase, decrypt it and use it for
/// decryption of a secret.
#[test]
fn age_encrypted_key_test() {
    // From `age-keygen`
    let key = "AGE-SECRET-KEY-1P5R9D3F743XGQJDQ02DR8PE2AVFCLKALYXRE4SP0YMYW9PTYW2TQPPDKFW";
    let pubkey =
        "age1ganl3gcyvjlnyh9373knv5du2hlhuafg6tp0elsz43q7fqu60s7qqural4";
    let mut state = AgeState {
        identity: None,
        last_error: None,
    };

    // Encrypt data with the public key
    let ciphertext = state.encrypt(PLAINTEXT, pubkey);

    // Encrypt the identity with a passphrase
    let encrypted_identity = state.encrypt_passphrase_armored(
        key.as_bytes(),
        Secret::new(PASSPHRASE.to_owned()),
    );
    assert_ok(&encrypted_identity);

    let encrypted_identity = encrypted_identity.unwrap();
    let encrypted_identity = String::from_utf8(encrypted_identity).unwrap();
    let encrypted_identity = encrypted_identity.as_str();

    // Unlock the `encrypted_identity` using the passphrase
    let _ = state.unlock_identity(&encrypted_identity, PASSPHRASE);

    let decrypted = state.decrypt(&ciphertext.unwrap());
    assert_ok(&decrypted);
    assert_eq!(decrypted.unwrap(), PLAINTEXT.as_bytes());

    state.lock_identity();
}

////////////////////////////////////////////////////////////////////////////////

fn assert_ok(result: &Result<Vec<u8>, AgeError>) {
    if let Some(err) = result.as_ref().err() {
        error!("{}", err);
    }
    assert!(result.is_ok())
}
