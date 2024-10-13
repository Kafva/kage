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
import javax.inject.Inject

@Singleton
class AgeRepository @Inject constructor(private val appRepository: AppRepository) {
    val autoLockSeconds: Long = 120

    private val _identityUnlockedAt = MutableStateFlow<Long?>(null)
    val identityUnlockedAt: StateFlow<Long?> = _identityUnlockedAt

    private val _plaintext = MutableStateFlow<String?>(null)
    val plaintext: StateFlow<String?> = _plaintext

    private val _passphrase = MutableStateFlow<String?>(null)
    val passphrase: StateFlow<String?> = _passphrase

    fun clearPlaintext() {
        _plaintext.value = null
    }

    fun setPassphrase(value: String?) {
        _passphrase.value = value
    }

    fun unlockIdentity(passphrase: String): Boolean {
        val encryptedIdentityPath = File("${appRepository.localRepo.toPath()}/.age-identities")
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

    fun decrypt(nodePath: String) {
        if (identityUnlockedAt.value == null) {
            return
        }
        _plaintext.value = Age.decrypt("${appRepository.filesDir.toPath()}/${nodePath}")
    }
}

