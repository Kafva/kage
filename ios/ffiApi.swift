import Foundation

@_silgen_name("ffi_git_clone")
public func ffi_git_clone(url: UnsafePointer<CChar>,
                          into: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_commit")
public func ffi_git_clone(repo: UnsafePointer<CChar>,
                          message: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_pull")
public func ffi_git_pull(repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_push")
public func ffi_git_push(repo: UnsafePointer<CChar>) -> CInt


@_silgen_name("ffi_age_encrypt")
public func ffi_age_encrypt(plaintext: UnsafePointer<CChar>,
                            recepient: UnsafePointer<CChar>,
                            out: UnsafeMutableRawPointer,
                            outsize: CInt) -> CInt

// @_silgen_name("ffi_age_decrypt_with_identity")
// public func ffi_age_decrypt_with_identity(ciphertext: UnsafePointer<CChar>,
//                                           encrypted_identity: UnsafePointer<CChar>,
//                                           passphrase: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?

@_silgen_name("ffi_free_cstring")
public func ffi_free_cstring(_ ptr: UnsafeMutablePointer<CChar>?) -> Void

