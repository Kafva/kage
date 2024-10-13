package kafva.kage.data

import java.io.File
import kafva.kage.jni.Age
import kafva.kage.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import dagger.hilt.components.SingletonComponent
import java.time.Instant
import java.util.Date
import javax.inject.Singleton

@Singleton
class AppRepository constructor(
    val versionName: String,
    val filesDir: File,
) {
    val autoLockSeconds: Long = 120
    val localRepoName = "git-adc83b19e"
    val localRepo: File = File("${filesDir}/${localRepoName}")

    private val _identityUnlockedAt = MutableStateFlow<Long?>(null)
    val identityUnlockedAt: StateFlow<Long?> = _identityUnlockedAt

    fun unlockIdentity(passphrase: String): Boolean {
        val encryptedIdentityPath = File("${localRepo.toPath()}/.age-identities")
        val encryptedIdentity = encryptedIdentityPath.readText(Charsets.UTF_8)
        val r = Age.unlockIdentity(encryptedIdentity, passphrase)
        if (r == 0) {
            _identityUnlockedAt.value = Instant.now().epochSecond
        }
        return _identityUnlockedAt.value != null
    }

    fun lockIdentity() {
        val r = Age.lockIdentity()
        if (r == 0) {
            _identityUnlockedAt.value = null
        }
    }

    fun decrypt(nodePath: String): String? {
        return Age.decrypt("${filesDir.toPath()}/${nodePath}")
    }
}

