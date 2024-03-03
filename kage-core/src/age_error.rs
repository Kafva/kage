
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
    Utf8Error(std::string::FromUtf8Error),
    BadRecepient,
    BadCipherInput,
    BadKey,
    NoIdentity,
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

impl From<std::string::FromUtf8Error> for AgeError {
    fn from(err: std::string::FromUtf8Error) -> AgeError {
        AgeError::Utf8Error(err)
    }
}

impl std::fmt::Display for AgeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
         use AgeError::*;
         match self {
             BadRecepient => f.write_str("Bad recepient format"),
             BadCipherInput => f.write_str("Bad ciphertext format"),
             BadKey => f.write_str("Bad key format"),
             NoIdentity => f.write_str("No identity loaded"),
             EncryptError(err) => err.fmt(f),
             DecryptError(err) => err.fmt(f),
             IoError(err) => err.fmt(f),
             Utf8Error(err) => err.fmt(f),
         }
    }
}
