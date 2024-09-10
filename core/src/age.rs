//! *.age:           x25519 encrypted files.
//! .age-recepients: The public x25519 key used to encrypt plaintext data into .age files.
//! .age-identities: Passphrase encrypted file, this contains the private
//!                  x25519 key used to decrypt .age files.
//!                  This should be in the ascii-armored format, i.e. created with `age -a`

use std::io::{Read, Write}; // For .read_to_end() and .write_all()

use crate::age_error::AgeError;

#[cfg(not(target_os = "android"))]
use crate::{error, level_to_color, log, log_prefix};

use age;
use age::secrecy::Secret;
use zeroize::Zeroize;

pub struct AgeState {
    /// Identity to use for decryption (public during tests)
    #[cfg(not(test))]
    identity: Option<age::x25519::Identity>,
    #[cfg(test)]
    pub identity: Option<age::x25519::Identity>,
    pub last_error: Option<AgeError>,
}

impl AgeState {
    pub fn default() -> Self {
        Self {
            identity: None,
            last_error: None,
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
                age_key.zeroize();
                return Ok(());
            };
        };

        age_key.zeroize();
        Err(AgeError::BadKey)
    }

    pub fn lock_identity(&mut self) {
        self.identity = None;
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
