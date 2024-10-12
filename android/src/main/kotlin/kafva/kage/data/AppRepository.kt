package kafva.kage.data

import java.io.File
import kafva.kage.jni.Age
import kafva.kage.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow


class AppRepository constructor(
    val versionName: String,
    val filesDir: File,
) {
    val localRepoName = "git-adc83b19e"
    val localRepo: File = File("${filesDir}/${localRepoName}")

    private val _identityIsUnlocked = MutableStateFlow<Boolean>(false)
    val identityIsUnlocked: StateFlow<Boolean> = _identityIsUnlocked

    fun unlockIdentity(passphrase: String): Boolean {
        val encryptedIdentity = "${localRepo.toPath().toString()}/.age-identities"
        Log.i(encryptedIdentity)
        val r = Age.unlockIdentity(encryptedIdentity, passphrase)
        if (r == 0) {
            _identityIsUnlocked.value = true
        }
        return _identityIsUnlocked.value
    }

    fun lockIdentity() {
        val r = Age.lockIdentity()
        if (r == 0) {
            _identityIsUnlocked.value = false
        }
    }

    fun decrypt(nodePath: String): String? {
        val str = Age.decrypt("${filesDir.toPath()}/${nodePath}")
        if (str == null) {
            Log.e("Decryption failed")
        }
        return str
    }

}

