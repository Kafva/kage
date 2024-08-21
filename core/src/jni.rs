use jni::sys::{jclass, jint};
use jni::JNIEnv;

#[no_mangle]
pub extern "system" fn Java_kafva_kage_MainActivityKt_test(
    env: *mut JNIEnv,
    class: jclass,
) -> jint {
    return 43;
}
