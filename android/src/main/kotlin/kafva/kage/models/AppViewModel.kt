package kafva.kage.models

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.launch
import java.io.File
import java.time.Instant
import javax.inject.Inject
import javax.inject.Singleton
import kafva.kage.Log
import kotlinx.coroutines.flow.stateIn
import kafva.kage.types.PwNode
import kotlin.text.lowercase
import kafva.kage.data.AppRepository
import kafva.kage.data.AgeRepository
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.LocalLifecycleOwner

@HiltViewModel
class AppViewModel @Inject constructor(
    val appRepository: AppRepository,
    val ageRepository: AgeRepository,
) : ViewModel() {

    fun onStateChange(lifecycleState: Lifecycle.State) {
        Log.d("State change: $lifecycleState")

        if (ageRepository.identityUnlockedAt.value == null) {
            return
        }
        val distance = Instant.now().epochSecond - (ageRepository.identityUnlockedAt.value ?: 0)
        if (distance >= ageRepository.autoLockSeconds) {
            ageRepository.lockIdentity()
            // Clear any decrypted plaintext from memory, the passphrase has
            // already been cleared.
            ageRepository.clearPlaintext()
            Log.d("Locked identity due to timeout [alive for $distance sec]")
        }
    }
}
