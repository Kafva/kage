//! *.age:           x25519 encrypted files.
//! .age-recepients: The public x25519 key used to encrypt plaintext data into .age files.
//! .age-identities: Passphrase encrypted file, this contains the private
//!                  x25519 key used to decrypt .age files.
//!                  This should be in the ascii-armored format, i.e. created with `age -a`

use std::io::{Read, Write, BufReader}; // For .read_to_end() and .write_all()
use std::fmt;

use super::{error,log,level_to_color,log_prefix};

use age;
use age::secrecy::Secret;

/// Max work factor during passphrase based decryption
const MAX_WORK_FACTOR: u8 = 40;

/// Common error type for all age operations, allows us to use `?` for
/// different types of operations in the same function
/// A conversion from each error type into an `AgeError` needs to be defined,
/// the derive_more crate can be used to generate these automatically.
///  https://jeltef.github.io/derive_more/derive_more/from.html
#[derive(Debug)]
pub enum AgeError {
    IoError(std::io::Error),
    EncryptError(age::EncryptError),
    DecryptError(age::DecryptError),
    InternalError,
    BadInput
}

impl From<std::io::Error> for AgeError {
    fn from(err: std::io::Error) -> AgeError {
        AgeError::IoError(err)
    }
}

impl From<age::EncryptError> for AgeError {
    fn from(err: age::EncryptError) -> AgeError {
        AgeError::EncryptError(err)
    }
}

impl From<age::DecryptError> for AgeError {
    fn from(err: age::DecryptError) -> AgeError {
        AgeError::DecryptError(err)
    }
}

impl fmt::Display for AgeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
         use AgeError::*;
         match self {
             InternalError => f.write_str("internal error"),
             BadInput => f.write_str("bad input"),
             EncryptError(err) => err.fmt(f),
             DecryptError(err) => err.fmt(f),
             IoError(err) => err.fmt(f),
         }
    }
}


/// Unlock `encrypted_identity` (given as an ascii-armored string) using
/// `passphrase` and decrypt `ciphertext` with the key contained in the
/// `encrypted_identity`.
pub fn age_decrypt_with_identity(ciphertext: &[u8],
                                 encrypted_identity: &str,
                                 passphrase: &str)  -> Result<Vec<u8>,AgeError> {

    let key = age_decrypt_passphrase_armored(encrypted_identity.as_bytes(), 
                                             Secret::new(passphrase.to_owned()))?;
    age_decrypt_with_raw_key(ciphertext, &key)
}

pub fn age_encrypt(plaintext: &str, recepient: &str) -> Result<Vec<u8>,AgeError> {
    match recepient.parse::<age::x25519::Recipient>() {
        Ok(pubkey) => {
            if let Some(encryptor) = age::Encryptor::with_recipients(vec![Box::new(pubkey)]) {

                let mut encrypted = vec![];
                let mut writer = encryptor.wrap_output(&mut encrypted)?;
                writer.write_all(plaintext.as_bytes())?;
                writer.finish()?;
                return Ok(encrypted)
            }
        },
        Err(e) => {
            error!("{}", e);
        }
    }

    Err(AgeError::InternalError)
}

#[cfg(test)]
fn age_decrypt(ciphertext: &[u8], key: &dyn age::Identity) -> Result<Vec<u8>,AgeError> {
    let decryptor = match age::Decryptor::new(ciphertext)? {
        age::Decryptor::Recipients(d) => d,
        _ => return Err(AgeError::BadInput),
    };

    let mut decrypted = vec![];
    let mut reader = decryptor.decrypt(std::iter::once(key as &dyn age::Identity))?;
    let _ = reader.read_to_end(&mut decrypted);

    Ok(decrypted)
}

#[cfg(test)]
fn age_encrypt_passphrase_armored(plaintext: &[u8],
                                  passphrase: Secret<String>) -> Result<Vec<u8>,AgeError> {
    let encryptor = age::Encryptor::with_user_passphrase(passphrase);

    let mut encrypted = vec![];
    let mut writer = encryptor.wrap_output(
        age::armor::ArmoredWriter::wrap_output(
            &mut encrypted,
            age::armor::Format::AsciiArmor,
        )?
    )?;
    writer.write_all(plaintext)?;
    writer.finish()
        .and_then(|armor| armor.finish())?;

    Ok(encrypted)
}

fn age_decrypt_passphrase_armored(ciphertext: &[u8],
                                  passphrase: Secret<String>) -> Result<Vec<u8>,AgeError> {
    let armored_reader = age::armor::ArmoredReader::new(ciphertext);
    let decryptor = match age::Decryptor::new(armored_reader)? {
        age::Decryptor::Passphrase(d) => d,
        _ => return Err(AgeError::BadInput)
    };

    let mut decrypted = vec![];
    let mut reader = decryptor.decrypt(&passphrase, Some(MAX_WORK_FACTOR))?;
    let _ = reader.read_to_end(&mut decrypted);

    Ok(decrypted)
}

fn age_decrypt_with_raw_key(ciphertext: &[u8], key: &[u8]) -> Result<Vec<u8>,AgeError> {
    let decryptor = match age::Decryptor::new(ciphertext)? {
        age::Decryptor::Recipients(d) => d,
        _ => return Err(AgeError::BadInput),
    };

    let reader = BufReader::new(key);
    let identities = age::IdentityFile::from_buffer(reader)?.into_identities();

    match identities.first() {
        Some(age::IdentityFileEntry::Native(key)) => {
            let mut decrypted = vec![];
            let mut reader = decryptor.decrypt(std::iter::once(key as &dyn age::Identity))?;
            let _ = reader.read_to_end(&mut decrypted);

            Ok(decrypted)
        }
        _ => Err(AgeError::BadInput)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::error;
    use age;

    const PLAINTEXT: &str = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
    const PASSPHRASE: &str = "pass: !#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";


    fn assert_ok(result: &Result<Vec<u8>, AgeError>) {
        if let Some(err) = result.as_ref().err() {
            error!("{}", err);
        }
        assert!(result.is_ok())
    }

    /// Encrypt and decrypt with a pair of x25519 keys
    #[test]
    fn age_key_test() {
        let key = age::x25519::Identity::generate();
        let pubkey = key.to_public();

        let ciphertext = age_encrypt(PLAINTEXT, pubkey.to_string().as_str());
        assert_ok(&ciphertext);

        let decrypted = age_decrypt(&ciphertext.unwrap(), &key);

        assert_ok(&decrypted);
        assert_eq!(decrypted.unwrap(), PLAINTEXT.as_bytes());
    }

    /// Encrypt and decrypt with a passphrase
    #[test]
    fn age_passphrase_test() {
        let ciphertext = age_encrypt_passphrase_armored(PLAINTEXT.as_bytes(),
                                                Secret::new(PASSPHRASE.to_owned()));
        assert_ok(&ciphertext);

        let decrypted = age_decrypt_passphrase_armored(&ciphertext.unwrap(),
                                               Secret::new(PASSPHRASE.to_owned()));

        assert_ok(&decrypted);
        assert_eq!(decrypted.unwrap(), PLAINTEXT.as_bytes());
    }

    /// Encrypt a private key with a passphrase, decrypt it and use it for
    /// decryption of a secret.
    #[test]
    fn age_encrypted_key_test() {
        // `age-keygen`
        let key = "AGE-SECRET-KEY-1P5R9D3F743XGQJDQ02DR8PE2AVFCLKALYXRE4SP0YMYW9PTYW2TQPPDKFW";
        let pubkey = "age1ganl3gcyvjlnyh9373knv5du2hlhuafg6tp0elsz43q7fqu60s7qqural4";

        let ciphertext = age_encrypt(PLAINTEXT, pubkey);

        let encrypted_identity = age_encrypt_passphrase_armored(key.as_bytes(),
                                                Secret::new(PASSPHRASE.to_owned()));
        assert_ok(&encrypted_identity);

        let decrypted_identity = age_decrypt_passphrase_armored(&encrypted_identity.unwrap(),
                                                Secret::new(PASSPHRASE.to_owned()));
        assert_ok(&decrypted_identity);
        let raw_key = decrypted_identity.unwrap();
        assert_eq!(raw_key, key.as_bytes());

        let decrypted = age_decrypt_with_raw_key(&ciphertext.unwrap(), raw_key.as_slice());
        assert_ok(&decrypted);
        assert_eq!(decrypted.unwrap(), PLAINTEXT.as_bytes());
    }
}
