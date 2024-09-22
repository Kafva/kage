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

    private val _nodes = MutableStateFlow<PwNode?>(null)
    val nodes: StateFlow<PwNode?> = _nodes

    private val _query = MutableStateFlow("")
    val query: StateFlow<String> = _query

    val searchMatches = combine(query, _nodes) { query, node ->
            val q = query.trim().lowercase()
            if (node != null && (query.isEmpty() || node.name.lowercase().contains(q))) {
                node
            } else {
                null
            }
        }.stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = _nodes.value
        )

    fun onQueryChanged(text: String) {
        Log.d("Current query: ${text}")
        _query.value = text
    }

    init {
        viewModelScope.launch {
            // Load password tree recursively
            val repoPath = File("${appContext.filesDir.path}/${GIT_DIR_NAME}/james")
            pwNodeRepository.load(repoPath)
            _nodes.value = pwNodeRepository.pwNodeStore
        }
    }


}
