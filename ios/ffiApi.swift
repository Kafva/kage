import Foundation

@_silgen_name("ffi_free_cstring")
public func ffi_free_cstring(_ ptr: UnsafeMutablePointer<CChar>?)

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

