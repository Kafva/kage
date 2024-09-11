use jni::objects::{JClass, JString};
use jni::sys::{jint, jsize};
use jni::JNIEnv;

use crate::age::age_try_lock;
use crate::age::AgeState;
use crate::age_error::AgeError;
use crate::log_android::__android_log_write;
use crate::KAGE_ERROR_LOCK_TAKEN;

macro_rules! jni_get_string {
    ($v:ident, $jni_env:ident, $age_state:ident) => {
        let Ok($v) = $jni_env.get_string(&$v) else {
            $age_state.last_error = Some(AgeError::GenericError);
            return -1 as jint;
        };
        let Ok($v) = $v.to_str() else {
            $age_state.last_error = Some(AgeError::GenericError);
            return -1 as jint;
        };
    };
}

#[no_mangle]
pub extern "system" fn Java_kafva_kage_Age_unlockIdentity<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    encrypted_identity: JString<'local>,
    passphrase: JString<'local>,
) -> jint {
    let Some(mut age_state) = age_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as jint;
    };

    jni_get_string!(encrypted_identity, env, age_state);
    jni_get_string!(passphrase, env, age_state);

    match age_state.unlock_identity(encrypted_identity, passphrase) {
        Err(err) => {
            error!("{}", err);
            age_state.last_error = Some(err);
            -1
        }
        _ => 0,
    }
}

#[no_mangle]
pub extern "system" fn Java_kafva_kage_Age_lockIdentity<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> jint {
    -1
}

#[no_mangle]
pub extern "system" fn Java_kafva_kage_Age_decrypt<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    encrypted_path: JString<'local>,
) -> JString<'local> {
    JString::default()
}

#[no_mangle]
pub extern "system" fn Java_kafva_kage_Age_strerror<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> JString<'local> {
    JString::default()
}
