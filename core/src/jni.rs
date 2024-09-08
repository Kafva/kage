use jni::objects::{JClass, JString};
use jni::sys::jint;
use jni::JNIEnv;
use once_cell::sync::Lazy;
use std::sync::Mutex;
use std::sync::MutexGuard;

use crate::git::git_clone;
use crate::git::git_pull;
use crate::git::git_setup;
use crate::git::git_log;
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
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> JString<'local> {
    let Some(mut git_last_error) = git_try_lock() else {
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
) -> JString<'local> {
    let Some(mut git_last_error) = git_try_lock() else {
        return JString::default();
    };

    let Ok(repo_path) = env.get_string(&repo_path) else {
        return JString::default();
    };
    let Ok(repo_path) = repo_path.to_str() else {
        return JString::default();
    };

    match git_log(repo_path) {
        Ok(arr) => {
            let s = arr.join("\n");
            let Ok(s) = env.new_string(s) else {
                return JString::default();
            };
            s
        },
        Err(err) => {
            error!("{}", err);
            return JString::default();
        }
    }
}
