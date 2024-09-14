package kafva.kage.data

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import java.io.File
import dagger.hilt.android.lifecycle.HiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kafva.kage.data.PwNodeRepository

@HiltViewModel
class PwNodeViewModel @Inject constructor(
    private val repository: PwNodeRepository
): ViewModel() {
    private val _pwNodes = MutableStateFlow<PwNode?>(null)
    val pwNodes: StateFlow<PwNode?> = _pwNodes

    init {
        val repoPath = File("/james")
        viewModelScope.launch {
            repository.load(repoPath)
            _pwNodes.value = repository.pwNodeStore
        }
    }
}

