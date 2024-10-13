package kafva.kage.models

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import androidx.lifecycle.asLiveData
import androidx.lifecycle.LiveData
import androidx.compose.runtime.collectAsState
import java.io.File
import javax.inject.Inject
import kafva.kage.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import android.content.Context
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.first
import kafva.kage.data.AgeRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.LocalLifecycleOwner

@HiltViewModel
class PasswordViewModel @Inject constructor(
    val ageRepository: AgeRepository
) : ViewModel() {

    // fun onStateChange(lifecycleState: Lifecycle.State) {
    //     Log.d("State change: $lifecycleState")
    //     if (appRepository.identityUnlockedAt.value == null) {
    //         plaintext.value = null
    //     }
    //     else {
    //         plaintext.value = viewModel.appRepository.decrypt(nodePath)
    //     }
    // }

}
