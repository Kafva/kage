import Foundation

@_silgen_name("ffi_git_clone")
public func ffi_git_clone(_ url: UnsafePointer<CChar>,
                          into: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_add")
public func ffi_git_add(_ repo: UnsafePointer<CChar>,
                        relativePath: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_commit")
public func ffi_git_commit(_ repo: UnsafePointer<CChar>,
                           message: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_pull")
public func ffi_git_pull(_ repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_push")
public func ffi_git_push(_ repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_index_has_local_changes")
public func ffi_git_index_has_local_changes(_ repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_age_unlock_identity")
public func ffi_age_unlock_identity(encryptedIdentity: UnsafePointer<CChar>,
                                    passphrase: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_age_lock_identity")
public func ffi_age_lock_identity() -> CInt

@_silgen_name("ffi_age_unlock_timestamp")
public func ffi_age_unlock_timestamp() -> CUnsignedLongLong


@_silgen_name("ffi_age_encrypt")
public func ffi_age_encrypt(plaintext: UnsafePointer<CChar>,
                            recepient: UnsafePointer<CChar>,
                            outpath: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_age_decrypt")
public func ffi_age_decrypt(encryptedFilepath: UnsafePointer<CChar>,
                            out: UnsafeMutableRawPointer,
                            outsize: CInt) -> CInt
