package kafva.kage.data

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject
import kafva.kage.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import android.content.Context

private const val GIT_DIR_NAME = "git-adc83b19e"

@HiltViewModel
class PwNodeViewModel @Inject constructor(
    @ApplicationContext appContext: Context,
    private val pwNodeRepository: PwNodeRepository,
) : ViewModel() {
        private val _pwNodes = MutableStateFlow<PwNode?>(null)
        val pwNodes: StateFlow<PwNode?> = _pwNodes

        init {
            viewModelScope.launch {
                // Load password tree recursively
                val repoPath = File("${appContext.filesDir.path}/${GIT_DIR_NAME}/james")
                pwNodeRepository.load(repoPath)
                _pwNodes.value = pwNodeRepository.pwNodeStore
            }
        }
    }
