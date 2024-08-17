import Foundation

@_silgen_name("ffi_age_unlock_identity")
func ffi_age_unlock_identity(
    encryptedIdentity: UnsafePointer<CChar>,
    passphrase: UnsafePointer<CChar>
) -> CInt

@_silgen_name("ffi_age_lock_identity")
func ffi_age_lock_identity() -> CInt

@_silgen_name("ffi_age_unlock_timestamp")
func ffi_age_unlock_timestamp() -> CUnsignedLongLong

@_silgen_name("ffi_age_encrypt")
func ffi_age_encrypt(
    plaintext: UnsafePointer<CChar>,
    recepient: UnsafePointer<CChar>,
    outpath: UnsafePointer<CChar>
) -> CInt

@_silgen_name("ffi_age_decrypt")
func ffi_age_decrypt(
    encryptedFilepath: UnsafePointer<CChar>,
    out: UnsafeMutableRawPointer,
    outsize: CInt
) -> CInt

@_silgen_name("ffi_age_strerror")
func ffi_age_strerror() -> UnsafeMutablePointer<CChar>?

////////////////////////////////////////////////////////////////////////////////

enum Age {
    static func unlockTimestamp() -> UInt64 {
        return ffi_age_unlock_timestamp()
    }

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
            throw AppError.ageError
        }
        G.logger.debug("OK: identity unlocked")

        let s = ffi_age_strerror()
        guard let s else {
            return
        }
        let msg = String(cString: s)
        G.logger.debug("Age library error: \(msg)")
        ffi_free_cstring(s)
    }

    static func lockIdentity() throws {
        if ffi_age_lock_identity() != 0 {
            throw AppError.ageError
        }
        G.logger.debug("OK: identity locked")
    }

    static func decrypt(_ at: URL) throws -> String {
        let pathC = try at.path().toCString()
        let outC = UnsafeMutableRawPointer.allocate(
            byteCount:
                Int(G.ageDecryptOutSize),
            alignment: 1)

        let written = ffi_age_decrypt(
            encryptedFilepath: pathC,
            out: outC,
            outsize: G.ageDecryptOutSize)

        if written <= 0 {
            outC.deallocate()
            throw AppError.ageError
        }
        let data = Data(bytes: outC, count: Int(written))

        let plaintext = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        outC.deallocate()
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
            throw AppError.ageError
        }
    }
}
