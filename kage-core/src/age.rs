//! *.age:           x25519 encrypted files.
//! .age-recepients: The public x25519 key used to encrypt plaintext data into .age files.
//! .age-identities: Passphrase encrypted file, this contains the private
//!                  x25519 key used to decrypt .age files.
//!                  This should be in the ascii-armored format, i.e. created with `age -a`

use std::io::{Read, Write}; // For .read_to_end() and .write_all()
use std::time::SystemTime;

use crate::age_error::AgeError;
use crate::{error, level_to_color, log, log_prefix};

use age;
use age::secrecy::Secret;
use zeroize::Zeroize;

pub struct AgeState {
    /// Identity to use for decryption
    identity: Option<age::x25519::Identity>,
    /// Timestamp when the identity was unlocked
    pub unlock_timestamp: Option<SystemTime>,
}

impl AgeState {
    pub fn default() -> Self {
        Self {
            identity: None,
            unlock_timestamp: None,
        }
    }

    fn decrypt_passphrase_armored(
        &mut self,
        ciphertext: &[u8],
        passphrase: Secret<String>,
    ) -> Result<Vec<u8>, AgeError> {
        let armored_reader = age::armor::ArmoredReader::new(ciphertext);
        let decryptor = match age::Decryptor::new(armored_reader)? {
            age::Decryptor::Passphrase(decryptor) => decryptor,
            _ => return Err(AgeError::BadCipherInput),
        };

        let mut decrypted = vec![];
        let mut reader = decryptor.decrypt(&passphrase, None)?;
        let _ = reader.read_to_end(&mut decrypted);

        Ok(decrypted)
    }

    /// Unlock `encrypted_identity` using `passphrase` and save the result
    pub fn unlock_identity(
        &mut self,
        encrypted_identity: &str,
        passphrase: &str,
    ) -> Result<(), AgeError> {
        let ciphertext = encrypted_identity.as_bytes();
        let passphrase = Secret::new(passphrase.to_owned());

        let age_key =
            self.decrypt_passphrase_armored(ciphertext, passphrase)?;

        let mut age_key = String::from_utf8(age_key.to_vec())?;

        // Private keys can contain comments, these need to be filtered out
        if let Some(key) =
            age_key.split('\n').filter(|a| !a.starts_with("#")).next()
        {
            if let Ok(identity) = key.parse::<age::x25519::Identity>() {
                self.identity = Some(identity);
                self.unlock_timestamp = Some(SystemTime::now());
                age_key.zeroize();
                return Ok(());
            };
        };

        age_key.zeroize();
        Err(AgeError::BadKey)
    }

    pub fn lock_identity(&mut self) {
        self.identity = None;
        self.unlock_timestamp = None;
    }

    pub fn decrypt(&self, ciphertext: &[u8]) -> Result<Vec<u8>, AgeError> {
        let Some(ref identity) = self.identity else {
            return Err(AgeError::NoIdentity);
        };

        let decryptor = match age::Decryptor::new(ciphertext)? {
            age::Decryptor::Recipients(decryptor) => decryptor,
            _ => return Err(AgeError::BadCipherInput),
        };

        let mut decrypted = vec![];
        let mut reader = decryptor
            .decrypt(std::iter::once(identity as &dyn age::Identity))?;
        let _ = reader.read_to_end(&mut decrypted);

        Ok(decrypted)
    }

    pub fn encrypt(
        &self,
        plaintext: &str,
        recepient: &str,
    ) -> Result<Vec<u8>, AgeError> {
        match recepient.parse::<age::x25519::Recipient>() {
            Ok(pubkey) => {
                if let Some(encryptor) =
                    age::Encryptor::with_recipients(vec![Box::new(pubkey)])
                {
                    let mut encrypted = vec![];
                    let mut writer = encryptor.wrap_output(&mut encrypted)?;
                    writer.write_all(plaintext.as_bytes())?;
                    writer.finish()?;
                    return Ok(encrypted);
                }
            }
            Err(e) => {
                error!("{}", e);
            }
        }

        Err(AgeError::BadRecepient)
    }

    #[cfg(test)]
    pub fn encrypt_passphrase_armored(
        &self,
        plaintext: &[u8],
        passphrase: Secret<String>,
    ) -> Result<Vec<u8>, AgeError> {
        let encryptor = age::Encryptor::with_user_passphrase(passphrase);

        let mut encrypted = vec![];
        let mut writer =
            encryptor.wrap_output(age::armor::ArmoredWriter::wrap_output(
                &mut encrypted,
                age::armor::Format::AsciiArmor,
            )?)?;
        writer.write_all(plaintext)?;
        writer.finish().and_then(|armor| armor.finish())?;

        Ok(encrypted)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::error;
    use age;
    use std::time::SystemTime;

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
        let identity = age::x25519::Identity::generate();
        let pubkey = identity.to_public();
        let state = AgeState {
            identity: Some(identity),
            unlock_timestamp: Some(SystemTime::now()),
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
            unlock_timestamp: None,
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
}
