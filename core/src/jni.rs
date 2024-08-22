use jni::sys::{jclass, jint};
use jni::JNIEnv;

#[no_mangle]
pub extern "system" fn Java_kafva_kage_KageCore_test(
    _env: *mut JNIEnv,
    _class: jclass,
) -> jint {
    return 43;
}
