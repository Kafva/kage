//use age::secrecy::Secret;
use derive_more::{From,Display};
use age::{Encryptor,Decryptor};
use age::x25519;
use super::{error,log,info,level_to_color,log_prefix};
use std::io::{Read, Write}; // .write_all() trait
use std::iter;

/// *.age:           x25519 encrypted files.
/// .age-recepients: The public x25519 key used to encrypt plaintext data into .age files.
/// .age-identities: Passphrase encrypted file, this contains the private
///                  x25519 key used to decrypt .age files.


/// Common error type for all age operations, allows us to use `?` for
/// different types of operations in the same function
/// A conversion from each error type into an `AgeError` needs to be defined,
/// the derive_more crate lets us do this without a lot of boilerplate.
///  https://jeltef.github.io/derive_more/derive_more/from.html
#[derive(From,Debug,Display)]
pub enum AgeError {
    IoError(std::io::Error),
    EncryptError(age::EncryptError),
    DecryptError(age::DecryptError),
    RecipientError
}

pub fn age_encrypt(plaintext: &str, recepient: &str) -> Result<Vec<u8>,AgeError> {
    match recepient.parse::<x25519::Recipient>() {
        Ok(pubkey) => {
            if let Some(encryptor) = Encryptor::with_recipients(vec![Box::new(pubkey)]) {

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

    Err(AgeError::RecipientError)
}

pub fn age_decrypt_passphrase(encrypted_path: &str, passphrase: &str) -> Result<Vec<u8>,AgeError> {
    // let decryptor = match age::Decryptor::new(&encrypted[..])? {
    //     age::Decryptor::Passphrase(d) => d,
    //     _ => unreachable!(),
    // };

    // let mut decrypted = vec![];
    // let mut reader = decryptor.decrypt(&Secret::new(passphrase.to_owned()), None)?;
    // reader.read_to_end(&mut decrypted);

    // decrypted
    Ok(vec![])
}

pub fn age_decrypt(ciphertext: &[u8], key: &dyn age::Identity) -> Result<Vec<u8>,AgeError> {
    let decryptor = match age::Decryptor::new(ciphertext)? {
        age::Decryptor::Recipients(d) => d,
        _ => unreachable!(),
    };

    let mut decrypted = vec![];
    let mut reader = decryptor.decrypt(iter::once(key as &dyn age::Identity))?;
    let _ = reader.read_to_end(&mut decrypted);

    Ok(decrypted)
}



#[cfg(test)]
mod tests {
    use super::*;
    use crate::error;
    use age;

    fn assert_ok(result: &Result<Vec<u8>, AgeError>) {
        if let Some(err) = result.as_ref().err() {
            error!("{}", err);
        }
        assert!(result.is_ok())
    }

    #[test]
    fn encrypt_and_decrypt_test() {
        let plaintext = "plaintext string";
        let key = age::x25519::Identity::generate();
        let pubkey = key.to_public();

        info!("pubkey: {}", pubkey);
        let ciphertext = age_encrypt(plaintext, pubkey.to_string().as_str());
        assert_ok(&ciphertext);

        let decrypted = age_decrypt(&ciphertext.unwrap(), &key);

        assert_ok(&decrypted);
        assert_eq!(decrypted.unwrap(), plaintext.as_bytes());
    }

    #[test]
    fn passphrase_decrypt_test() {

    }

}


// // Encrypt the plaintext to a ciphertext using the passphrase...
// let encrypted = {
//     let encryptor = age::Encryptor::with_user_passphrase(Secret::new(passphrase.to_owned()));

//     let mut encrypted = vec![];
//     let mut writer = encryptor.wrap_output(&mut encrypted)?;
//     writer.write_all(plaintext)?;
//     writer.finish()?;

//     encrypted
// };

// // ... and decrypt the ciphertext to the plaintext again using the same passphrase.
// let decrypted = {
//     let decryptor = match age::Decryptor::new(&encrypted[..])? {
//         age::Decryptor::Passphrase(d) => d,
//         _ => unreachable!(),
//     };

//     let mut decrypted = vec![];
//     let mut reader = decryptor.decrypt(&Secret::new(passphrase.to_owned()), None)?;
//     reader.read_to_end(&mut decrypted);

//     decrypted
// };

// assert_eq!(decrypted, plaintext);
