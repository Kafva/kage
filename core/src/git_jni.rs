use jni::objects::{JClass, JObjectArray, JString};
use jni::sys::{jint, jsize};
use jni::JNIEnv;

use crate::git::git_clone;
use crate::git::git_log;
use crate::git::git_reset;
use crate::git::git_stage;
use crate::git::git_commit;
use crate::git::git_setup;
use crate::git::git_try_lock;
use crate::git::git_config_set_user;
use crate::git_call;
use crate::KAGE_ERROR_LOCK_TAKEN;

macro_rules! load_jstring {
    ($env:ident, $string:ident) => (
        let Ok($string) = $env.get_string(&$string) else {
            return -1 as jint;
        };
        let Ok($string) = $string.to_str() else {
            return -1 as jint;
        };
    )
}

#[no_mangle]
pub extern "system" fn Java_one_kafva_kage_jni_Git_clone<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    url: JString<'local>,
    into: JString<'local>,
) -> jint {
    let Some(mut git_last_error) = git_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as jint;
    };

    git_setup();

    load_jstring!(env, url);
    load_jstring!(env, into);
    git_call!(git_clone(url, into), git_last_error) as jint
}

#[no_mangle]
pub extern "system" fn Java_one_kafva_kage_jni_Git_setUser<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    repo_path: JString<'local>,
    username: JString<'local>,
) -> jint {
    let Some(mut git_last_error) = git_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as jint;
    };

    load_jstring!(env, repo_path);
    load_jstring!(env, username);
    git_call!(git_config_set_user(repo_path, username), git_last_error) as jint
}

#[no_mangle]
pub extern "system" fn Java_one_kafva_kage_jni_Git_stage<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    repo_path: JString<'local>,
    relative_path: JString<'local>,
) -> jint {
    let Some(mut git_last_error) = git_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as jint;
    };

    load_jstring!(env, repo_path);
    load_jstring!(env, relative_path);
    git_call!(git_stage(repo_path, relative_path), git_last_error) as jint
}

#[no_mangle]
pub extern "system" fn Java_one_kafva_kage_jni_Git_reset<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    repo_path: JString<'local>,
) -> jint {
    let Some(mut git_last_error) = git_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as jint;
    };

    load_jstring!(env, repo_path);
    git_call!(git_reset(repo_path), git_last_error) as jint
}

#[no_mangle]
pub extern "system" fn Java_one_kafva_kage_jni_Git_commit<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    repo_path: JString<'local>,
    message: JString<'local>,
) -> jint {
    let Some(mut git_last_error) = git_try_lock() else {
        return KAGE_ERROR_LOCK_TAKEN as jint;
    };

    load_jstring!(env, repo_path);
    load_jstring!(env, message);
    git_call!(git_commit(repo_path, message), git_last_error) as jint
}

#[no_mangle]
pub extern "system" fn Java_one_kafva_kage_jni_Git_strerror<'local>(
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
pub extern "system" fn Java_one_kafva_kage_jni_Git_log<'local>(
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

            let Ok(initial_value) = env.new_string("") else {
                error!("Error creating empty Java string");
                return JObjectArray::default();
            };
            let Ok(outarr) = env.new_object_array(size, "java/lang/String", initial_value)
            else {
                error!("Error creating Java object array");
                return JObjectArray::default();
            };

            for (i,item) in arr.into_iter().enumerate() {
                let Ok(s) = env.new_string(&item) else {
                    error!("Error creating Java string from: '{}'", item);
                    return JObjectArray::default();
                };

                let Ok(_) = env.set_object_array_element(&outarr, i as i32, s) else {
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
