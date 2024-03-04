import Foundation


struct Age {
    static func unlockTimestamp() -> UInt64 {
        return ffi_age_unlock_timestamp()
    }

    static func unlockIdentity(_ encryptedIdentity: URL,
                               passphrase: String) -> Bool {
        do {
            let encryptedIdentity = try String(contentsOf: encryptedIdentity,
                                               encoding: .utf8)
            let encryptedIdentityC = try encryptedIdentity.toCString()
            let passphraseC        = try passphrase.toCString()

            let r = ffi_age_unlock_identity(encryptedIdentity: encryptedIdentityC,
                                            passphrase: passphraseC)

            if r == 0 {
                G.logger.info("OK: identity unlocked")
                return true
            }

        } catch {
            G.logger.error("\(error)")
        }

        return false
    }

    static func lockIdentity() -> Bool {
        let r = ffi_age_lock_identity()

        if r == 0 {
            G.logger.info("OK: identity locked")
            return true
        }
        return false
    }

    static func decrypt(_ at: URL) -> String {
        do {
            let pathC = try at.path().toCString()
            let outC = UnsafeMutableRawPointer.allocate(byteCount:
                                                        Int(G.ageDecryptOutSize),
                                                        alignment: 1)

            let written = ffi_age_decrypt(encryptedFilepath: pathC,
                                          out: outC,
                                          outsize: G.ageDecryptOutSize)

            if written > 0 {
                let data = Data(bytes: outC, count: Int(written))

                let plaintext = String(decoding: data, as: UTF8.self)
                                .trimmingCharacters(in: .whitespacesAndNewlines)

                if !plaintext.isEmpty {
                    outC.deallocate()
                    return plaintext
                }
            }

            outC.deallocate()
            G.logger.error("Decryption failed: \(Int(written))")

        } catch {
            G.logger.error("\(error)")
        }

        return ""
    }

    static func encrypt(recipient: URL,
                        outpath: URL,
                        plaintext: String) -> Bool {
        do {
            let recepient = (try String(contentsOf: recipient, encoding: .utf8))
                                .trimmingCharacters(in: .whitespacesAndNewlines)

            let recepientC = try recepient.toCString()
            let plaintextC = try plaintext
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .toCString()
            let outpathC   = try outpath.path().toCString()

            let r = ffi_age_encrypt(plaintext: plaintextC,
                                    recepient: recepientC,
                                    outpath: outpathC)
            return r == 0
        } catch {
            G.logger.error("\(error)")
        }
        return false
    }
}
