package kafva.kage.data

import java.io.File
import kafva.kage.jni.Age as Jni
import kafva.kage.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import dagger.hilt.components.SingletonComponent
import java.time.Instant
import java.util.Date
import javax.inject.Singleton
import javax.inject.Inject

class AgeException(message: String): Exception(message)

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

    @Throws(AgeException::class)
    fun unlockIdentity(passphrase: String) {
        val encryptedIdentityPath = File("${appRepository.localRepo.toPath()}/.age-identities")
        val encryptedIdentity = encryptedIdentityPath.readText(Charsets.UTF_8)
        val r = Jni.unlockIdentity(encryptedIdentity, passphrase)
        if (r != 0) {
            raiseError()
        }
        else {
            _identityUnlockedAt.value = Instant.now().epochSecond
        }
    }

    fun lockIdentity() {
        val r = Jni.lockIdentity()
        if (r == 0) {
            _identityUnlockedAt.value = null
        }
    }

    @Throws(AgeException::class)
    fun decrypt(nodePath: String) {
        if (identityUnlockedAt.value == null) {
            return
        }
        val value = Jni.decrypt("${appRepository.filesDir.toPath()}/${nodePath}")
        if (value == null) {
            raiseError()
        }
        else {
            _plaintext.value = value
        }
    }

    @Throws(AgeException::class)
    private fun raiseError() {
        val message = Jni.strerror()
        if (message != null) {
            throw AgeException(message)
        }
        else {
            throw AgeException("Unknown error")
        }
    }
}

