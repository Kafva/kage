import Foundation

@_silgen_name("add")
public func rust_add(a: Int32, b: Int32) -> Int32

@_silgen_name("get_cstring")
public func rust_cstring() -> UnsafeMutablePointer<Int8>

@_silgen_name("free_cstring")
public func rust_free_cstring(_ ptr: UnsafeMutablePointer<Int8>?)

@_silgen_name("get_identity")
public func rust_identity() -> UnsafeMutablePointer<Int8>

