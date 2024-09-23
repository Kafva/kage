package kafva.kage.data

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
import kafva.kage.Log
import kotlinx.coroutines.flow.stateIn
import kafva.kage.data.PwNode
import kotlin.text.lowercase

private const val GIT_DIR_NAME = "git-adc83b19e"

@HiltViewModel
class TreeViewModel @Inject constructor(
    @ApplicationContext appContext: Context,
    private val pwNodeRepository: PwNodeRepository,
) : ViewModel() {

    val expandRecursively = MutableStateFlow<Boolean>(true)

    private val _rootNode = MutableStateFlow<PwNode?>(null)
    val rootNode: StateFlow<PwNode?> = _rootNode

    private val _query = MutableStateFlow("")
    val query: StateFlow<String> = _query

    private val _searchMatches = MutableStateFlow<List<PwNode>>(listOf())
    val searchMatches: StateFlow<List<PwNode>> = _searchMatches

    fun onQueryChanged(text: String) {
        Log.d("Current query: ${text}")
        _query.value = text.lowercase()
        if (_rootNode.value != null) {
            _searchMatches.value = _rootNode.value!!.findChildren(_query.value)
        }
    }

    init {
        viewModelScope.launch {
            // Load password tree recursively
            val repoPath = File("${appContext.filesDir.path}/${GIT_DIR_NAME}")
            pwNodeRepository.load(repoPath)
            _rootNode.value = pwNodeRepository.rootNode
            // Initialize with all nodes in the search result
            if (_rootNode.value != null) {
                _searchMatches.value = _rootNode.value!!.findChildren("")
            }
        }
    }
}
