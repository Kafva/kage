use jni::objects::{JClass, JString};
use jni::sys::jint;
use jni::JNIEnv;

use totp::calculate_totp_now;

use crate::age::age_try_lock;
use crate::age_error::AgeError;
use crate::util::path_to_filename;
use crate::KAGE_ERROR_LOCK_TAKEN;

macro_rules! jni_get_string {
    ($v:ident, $jni_env:ident, $age_state:ident, $ret_err:expr) => {
        let Ok($v) = $jni_env.get_string(&$v) else {
            $age_state.last_error = Some(AgeError::GenericError);
            return $ret_err;
        };
        let Ok($v) = $v.to_str() else {
            $age_state.last_error = Some(AgeError::GenericError);
            return $ret_err;
        };
    };
}

#[no_mangle]
pub extern "system" fn Java_one_kafva_kage_jni_Age_unlockIdentity<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    encrypted_identity: JString<'local>,
    passphrase: JString<'local>,
) -> jint {
    let Some(mut age_state) = age_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as jint;
    };

    jni_get_string!(encrypted_identity, env, age_state, -1 as jint);
    jni_get_string!(passphrase, env, age_state, -1 as jint);

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
pub extern "system" fn Java_one_kafva_kage_jni_Age_lockIdentity<'local>(
    _env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> jint {
    let Some(mut age_state) = age_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as jint;
    };
    age_state.lock_identity();
    0
}

#[no_mangle]
pub extern "system" fn Java_one_kafva_kage_jni_Age_decrypt<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    encrypted_path: JString<'local>,
) -> JString<'local> {
    let Some(mut age_state) = age_try_lock() else {
        return JString::default();
    };

    jni_get_string!(encrypted_path, env, age_state, JString::default());

    let Some(filename) = path_to_filename(encrypted_path) else {
        age_state.last_error = Some(AgeError::GenericError);
        return JString::default();
    };

    match std::fs::read(encrypted_path) {
        Ok(data) => match age_state.decrypt(data.as_slice()) {
            Ok(data) => {
                let Ok(s) = String::from_utf8(data) else {
                    return JString::default();
                };
                if encrypted_path.ends_with("otp.age") {
                    match calculate_totp_now(s.as_str()) {
                        Ok((code, _)) => {
                            let Ok(s) = env.new_string(code) else {
                                return JString::default();
                            };
                            return s;
                        },
                        Err(err) => {
                            error!("{}: {}", filename, err);
                            age_state.last_error = Some(AgeError::TotpError(err));
                            return JString::default();
                        }
                    }
                }
                else {
                    let Ok(s) = env.new_string(s) else {
                        return JString::default();
                    };
                    return s;
                }
            }
            Err(err) => {
                error!("{}: {}", filename, err);
                age_state.last_error = Some(err)
            }
        },
        Err(err) => {
            error!("{}: {}", filename, err);
            age_state.last_error = Some(AgeError::IoError(err))
        }
    }
    JString::default()
}

#[no_mangle]
pub extern "system" fn Java_one_kafva_kage_jni_Age_strerror<'local>(
    env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> JString<'local> {
    let Some(mut age_state) = age_try_lock() else {
        return JString::default();
    };
    let Some(ref err) = age_state.last_error else {
        return JString::default();
    };
    let s = err.to_string();

    let Ok(s) = env.new_string(&s) else {
        return JString::default();
    };

    age_state.last_error = None;
    s
}
