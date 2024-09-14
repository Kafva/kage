package kafva.kage.data

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

@HiltViewModel
class PwNodeViewModel
    @Inject
    constructor(
        private val repository: PwNodeRepository,
    ) : ViewModel() {
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
