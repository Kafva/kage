package kafva.kage.data

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import androidx.lifecycle.asLiveData
import androidx.lifecycle.LiveData
import java.io.File
import javax.inject.Inject
import kafva.kage.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import android.content.Context
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kafva.kage.di.GitContext

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val gitContext: GitContext,
    private val settingsRepository: SettingsRepository
) : ViewModel() {

    fun updateSettings(newSettings: Settings) =
        viewModelScope.launch {
            settingsRepository.updateSettings(newSettings)
            Log.i("Updated remoteAddress: ${newSettings.remoteAddress}")
        }

    val currentSettings: Flow<Settings> = settingsRepository.settings

    fun clone() {
        viewModelScope.launch {
            settingsRepository.settings.collect { s ->
                gitContext.clone(s.remoteAddress)
            }
        }
    }

    init {
        viewModelScope.launch {
            settingsRepository.settings.collect { s ->
                Log.i("Loaded remoteAddress: ${s.remoteAddress}")
            }
        }
    }
}
