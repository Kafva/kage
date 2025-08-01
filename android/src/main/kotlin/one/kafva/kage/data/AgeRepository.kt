package one.kafva.kage.data

import androidx.lifecycle.Lifecycle
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import one.kafva.kage.AUTO_LOCK_SECONDS
import one.kafva.kage.Log
import java.io.File
import java.time.Instant
import javax.inject.Inject
import javax.inject.Singleton
import one.kafva.kage.jni.Age as Jni

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

        private val _password = MutableStateFlow<String?>(null)
        val password: StateFlow<String?> = _password

        private fun clearPlaintext() {
            _plaintext.value = null
        }

        fun setPassword(value: String?) {
            _password.value = value
        }

        @Throws(AgeException::class)
        fun unlockIdentity(password: String) {
            val encryptedIdentityPath =
                File("${appRepository.localRepo.toPath()}/.age-identities")
            val encryptedIdentity =
                encryptedIdentityPath.readText(
                    Charsets.UTF_8,
                )
            val r = Jni.unlockIdentity(encryptedIdentity, password)
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
            if (distance >= AUTO_LOCK_SECONDS) {
                lockIdentity()
                // Clear any decrypted plaintext from memory, the password has
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
