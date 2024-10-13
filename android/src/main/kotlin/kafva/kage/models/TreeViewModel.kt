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
import javax.inject.Inject
import javax.inject.Singleton
import kafva.kage.Log
import kotlinx.coroutines.flow.stateIn
import kafva.kage.types.PwNode
import kotlin.text.lowercase
import kafva.kage.data.GitRepository
import kafva.kage.data.AppRepository
import kafva.kage.data.RuntimeSettingsRepository

/// Keep mutable state flows private, and expose non-modifiable state-flows
@HiltViewModel
class TreeViewModel @Inject constructor(
    val appRepositoy: AppRepository,
    val gitRepository: GitRepository,
    val runtimeSettingsRepository: RuntimeSettingsRepository,
) : ViewModel() {

    init {
        // Load nodes from git repository when initialising the view
        viewModelScope.launch {
            gitRepository.setup()
        }
    }
}
