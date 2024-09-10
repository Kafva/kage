use jni::objects::{JClass, JObject, JObjectArray, JString};
use jni::sys::{jint, jsize};
use jni::JNIEnv;

use crate::git::git_clone;
use crate::git::git_log;
use crate::git::git_pull;
use crate::git::git_setup;
use crate::git::git_try_lock;
use crate::git_call;
use crate::log_android::__android_log_write;
use crate::KAGE_ERROR_LOCK_TAKEN;

#[no_mangle]
pub extern "system" fn Java_kafva_kage_Git_clone<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    url: JString<'local>,
    into: JString<'local>,
) -> jint {
    let Some(mut git_last_error) = git_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as jint;
    };

    git_setup();

    let Ok(url) = env.get_string(&url) else {
        return -1 as jint;
    };
    let Ok(url) = url.to_str() else {
        return -1 as jint;
    };

    let Ok(into) = env.get_string(&into) else {
        return -1 as jint;
    };
    let Ok(into) = into.to_str() else {
        return -1 as jint;
    };

    git_call!(git_clone(url, into), git_last_error) as jint
}

#[no_mangle]
pub extern "system" fn Java_kafva_kage_Git_pull<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    repo_path: JString<'local>,
) -> jint {
    let Some(mut git_last_error) = git_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as jint;
    };

    let Ok(repo_path) = env.get_string(&repo_path) else {
        return -1 as jint;
    };
    let Ok(repo_path) = repo_path.to_str() else {
        return -1 as jint;
    };

    git_call!(git_pull(repo_path), git_last_error) as jint
}

#[no_mangle]
pub extern "system" fn Java_kafva_kage_Git_strerror<'local>(
    env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> JString<'local> {
    let Some(git_last_error) = git_try_lock() else {
        return JString::default();
    };
    let Some(err) = git_last_error.as_ref() else {
        return JString::default();
    };

    let Ok(msg) = env.new_string(err.message()) else {
        return JString::default();
    };

    msg
}

#[no_mangle]
pub extern "system" fn Java_kafva_kage_Git_log<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    repo_path: JString<'local>,
) -> JObjectArray<'local> {
    let Some(_git_last_error) = git_try_lock() else {
        return JObjectArray::default();
    };

    let Ok(repo_path) = env.get_string(&repo_path) else {
        return JObjectArray::default();
    };
    let Ok(repo_path) = repo_path.to_str() else {
        return JObjectArray::default();
    };

    match git_log(repo_path) {
        Ok(arr) => {
            let size = arr.len() as jsize;

            let Some(first) = arr.first() else {
                error!("Empty commit log");
                return JObjectArray::default();
            };

            let Ok(s) = env.new_string(first) else {
                error!("Error creating Java string from: '{}'", first);
                return JObjectArray::default();
            };

            let Ok(outarr) = env.new_object_array(size, "java/lang/String", s)
            else {
                error!("Error creating Java object array");
                return JObjectArray::default();
            };

            for item in arr.into_iter().skip(1) {
                let Ok(s) = env.new_string(&item) else {
                    error!("Error creating Java string from: '{}'", item);
                    return JObjectArray::default();
                };

                let Ok(_) = env.set_object_array_element(&outarr, 0, s) else {
                    error!("Error adding Java string to array: '{}'", item);
                    return JObjectArray::default();
                };
            }

            outarr
        }
        Err(err) => {
            error!("{}", err);
            return JObjectArray::default();
        }
    }
}

#[no_mangle]
pub extern "system" fn Java_kafva_kage_Age_unlockIdentity<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    encrypted_identity: JString<'local>,
    passphrase: JString<'local>,
) -> jint {
    -1
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
