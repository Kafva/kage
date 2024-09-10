import Foundation

@_silgen_name("ffi_age_unlock_identity")
func ffi_age_unlock_identity(
    encryptedIdentity: UnsafePointer<CChar>,
    passphrase: UnsafePointer<CChar>
) -> CInt

@_silgen_name("ffi_age_lock_identity")
func ffi_age_lock_identity() -> CInt

@_silgen_name("ffi_age_encrypt")
func ffi_age_encrypt(
    plaintext: UnsafePointer<CChar>,
    recepient: UnsafePointer<CChar>,
    outpath: UnsafePointer<CChar>
) -> CInt

@_silgen_name("ffi_age_decrypt")
func ffi_age_decrypt(encryptedFilepath: UnsafePointer<CChar>)
    -> UnsafeMutablePointer<CChar>?

@_silgen_name("ffi_age_strerror")
func ffi_age_strerror() -> UnsafeMutablePointer<CChar>?

////////////////////////////////////////////////////////////////////////////////

enum Age {

    static func unlockIdentity(
        _ encryptedIdentity: URL,
        passphrase: String
    ) throws {
        let encryptedIdentity = try String(
            contentsOf: encryptedIdentity,
            encoding: .utf8)
        let encryptedIdentityC = try encryptedIdentity.toCString()
        let passphraseC = try passphrase.toCString()

        let r = ffi_age_unlock_identity(
            encryptedIdentity: encryptedIdentityC,
            passphrase: passphraseC)

        if r != 0 {
            try throwError(code: r)
        }
        G.logger.debug("OK: identity unlocked")
    }

    static func lockIdentity() throws {
        let r = ffi_age_lock_identity()
        if r != 0 {
            try throwError(code: r)
        }
        G.logger.debug("OK: identity locked")
    }

    static func decrypt(_ at: URL) throws -> String {
        let pathC = try at.standardizedFileURL.path().toCString()

        let plaintextC = ffi_age_decrypt(encryptedFilepath: pathC)

        guard let plaintextC else {
            try throwError(code: -1)
            return ""  // Prior call always throws, this should never happen
        }

        let plaintext = String(cString: plaintextC)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        ffi_free_cstring(plaintextC)

        return plaintext
    }

    static func encrypt(
        recipient: URL,
        outpath: URL,
        plaintext: String
    ) throws {
        let recepient = (try String(contentsOf: recipient, encoding: .utf8))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let recepientC = try recepient.toCString()
        let plaintextC =
            try plaintext
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .toCString()
        let outpathC = try outpath.path().toCString()

        let r = ffi_age_encrypt(
            plaintext: plaintextC,
            recepient: recepientC,
            outpath: outpathC)
        if r != 0 {
            try throwError(code: r)
        }
    }

    static private func throwError(code: CInt) throws {
        let s = ffi_age_strerror()
        guard let s else {
            throw AppError.ageError("code \(code)")
        }

        let msg = String(cString: s)
        ffi_free_cstring(s)

        throw AppError.ageError(msg)
    }

}
