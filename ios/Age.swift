import Foundation

/// Decryption/encryption API
struct Age {
    static func unlockIdentity(_ encryptedIdentity: URL,
                               passphrase: String) -> Bool {
        do {
            let encryptedIdentity = try String(contentsOf: encryptedIdentity, encoding: .utf8)

            let encryptedIdentityC = try guardLet(encryptedIdentity.cString(using: .utf8),
                                                  AppError.cStringError)
            let passphraseC        = try guardLet(passphrase.cString(using: .utf8),
                                                  AppError.cStringError)


            let r = ffi_age_unlock_identity(encryptedIdentity: encryptedIdentityC,
                                            passphrase: passphraseC)

            if r == 0 {
                logger.info("OK: identity unlocked")
                return true
            }

        } catch {
            logger.error("\(error)")
        }

        return false
    }

    static func lockIdentity() -> Bool {
        let r = ffi_age_lock_identity()

        if r == 0 {
            logger.info("OK: identity locked")
            return true
        }
        return false
    }

    static func decrypt(_ at: URL) -> String {
        do {
            let outsize: CInt = 1024
            let pathC = try guardLet(at.path().cString(using: .utf8), AppError.cStringError)
            let outC = UnsafeMutableRawPointer.allocate(byteCount: Int(outsize), alignment: 1)

            let written = ffi_age_decrypt(encryptedFilepath: pathC,
                                          out: outC,
                                          outsize: outsize)

            if written > 0 {
                let data = Data(bytes: outC, count: Int(written))

                let plaintext = String(decoding: data, as: UTF8.self)

                if !plaintext.isEmpty {
                    outC.deallocate()
                    return plaintext
                }
            }

            outC.deallocate()
            logger.error("Decryption failed: \(Int(written))")

        } catch {
            logger.error("\(error)")
        }

        return ""
    }

    static func encrypt(recipient: URL,
                        outpath: URL,
                        plaintext: String) -> Bool {
        do {
            let recepient = (try String(contentsOf: recipient, encoding: .utf8))
                                .trimmingCharacters(in: .whitespacesAndNewlines)

            let recepientC = try guardLet(recepient.cString(using: .utf8),
                                          AppError.cStringError)
            let plaintextC = try guardLet(plaintext.cString(using: .utf8),
                                          AppError.cStringError)
            let outpathC   = try guardLet(outpath.path().cString(using: .utf8),
                                          AppError.cStringError)

            let r = ffi_age_encrypt(plaintext: plaintextC,
                                    recepient: recepientC,
                                    outpath: outpathC)
            return r == 0
        } catch {
            logger.error("\(error)")
        }
        return false
    }
}
