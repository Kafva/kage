package kafva.kage.data

import androidx.lifecycle.Lifecycle
import kafva.kage.G
import kafva.kage.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.io.File
import java.time.Instant
import javax.inject.Inject
import javax.inject.Singleton
import kafva.kage.jni.Age as Jni

class AgeException(
    message: String,
) : Exception(message)

@Singleton
class AgeRepository
    @Inject
    constructor(
        private val appRepository: AppRepository,
    ) {
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
            val encryptedIdentityPath =
                File("${appRepository.localRepo.toPath()}/.age-identities")
            val encryptedIdentity =
                encryptedIdentityPath.readText(
                    Charsets.UTF_8,
                )
            val r = Jni.unlockIdentity(encryptedIdentity, passphrase)
            if (r != 0) {
                raiseError()
            } else {
                _identityUnlockedAt.value = Instant.now().epochSecond
            }
        }

        fun onStateChange(lifecycleState: Lifecycle.State) {
            Log.d("State change: $lifecycleState")

            if (identityUnlockedAt.value == null) {
                return
            }
            val distance =
                Instant.now().epochSecond - (identityUnlockedAt.value ?: 0)
            if (distance >= G.AUTO_LOCK_SECONDS) {
                lockIdentity()
                // Clear any decrypted plaintext from memory, the passphrase has
                // already been cleared.
                clearPlaintext()
                Log.d(
                    "Locked identity due to timeout [alive for $distance sec]",
                )
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
            val value =
                Jni.decrypt(
                    "${appRepository.filesDir.toPath()}/$nodePath",
                )
            if (value == null) {
                raiseError()
            } else {
                _plaintext.value = value
            }
        }

        @Throws(AgeException::class)
        private fun raiseError() {
            val message = Jni.strerror()
            if (message != null) {
                throw AgeException(message)
            } else {
                throw AgeException("Unknown error")
            }
        }
    }
