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
import android.content.pm.PackageInfo
import androidx.compose.runtime.MutableState
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.first
import kafva.kage.data.GitRepository
import kafva.kage.data.AppRepository
import kafva.kage.data.SettingsRepository
import kafva.kage.types.Settings
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kafva.kage.data.GitException

@HiltViewModel
class SettingsViewModel @Inject constructor(
    val gitRepository: GitRepository,
    val settingsRepository: SettingsRepository,
    val appRepository: AppRepository,
) : ViewModel() {

    fun updateSettings(s: Settings) =
        viewModelScope.launch {
            settingsRepository.updateSettings(s)
        }

    @Throws(GitException::class)
    fun clone(currentError: MutableState<String?>) {
        viewModelScope.launch {
            settingsRepository.flow.collect { s ->
                try {
                    gitRepository.clone("git://${s.remoteAddress}/${s.remoteRepoPath}")
                    currentError.value = null
                }
                catch (e: GitException) {
                    currentError.value = e.message
                    Log.e(e.message ?: "Unknown error")
                }
            }
        }
    }
}
