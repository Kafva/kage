import Foundation

@_silgen_name("free_cstring")
public func rust_free_cstring(_ ptr: UnsafeMutablePointer<CChar>?)

@_silgen_name("get_identity")
public func rust_identity() -> UnsafeMutablePointer<CChar>

@_silgen_name("git_init")
public func rust_git_init(_ ptr: UnsafePointer<CChar>)

