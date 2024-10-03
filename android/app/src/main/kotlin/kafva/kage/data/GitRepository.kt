package kafva.kage.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton
import java.io.File
import javax.inject.Inject
import kafva.kage.data.PwNode
import kafva.kage.Log
import kafva.kage.jni.Git as Jni
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kafva.kage.types.CommitInfo

@Singleton
class GitRepository @Inject constructor(val filesDir: String) {
    val localRepoName = "git-adc83b19e"
    val repoPath: File = File("${filesDir}/${localRepoName}")
    val repoStr = repoPath.toPath().toString()

    private val _query = MutableStateFlow("")
    val query: StateFlow<String> = _query

    private val _searchMatches = MutableStateFlow<List<PwNode>>(listOf())
    val searchMatches: StateFlow<List<PwNode>> = _searchMatches

    private val _rootNode = MutableStateFlow<PwNode?>(null)
    val rootNode: StateFlow<PwNode?> = _rootNode

    /// Load password tree recursively
    fun setup() {
        _rootNode.value = PwNode(repoPath, listOf())
        // Populate the search result with all nodes
        _searchMatches.value = rootNode.value?.findChildren(_query.value) ?: listOf()
    }

    fun updateMatches(text: String) {
        Log.d("Updated query: ${query.value}")
        _query.value = text.lowercase()
        _searchMatches.value = rootNode.value?.findChildren(query.value) ?: listOf()
    }

    /// Reclone from URL
    fun clone(url: String): String? {
        Log.v("Recloning into $repoPath...")
        repoPath.deleteRecursively()

        val r = Jni.clone(url, repoStr)
        Log.v("Clone done: $r")
        if (r != 0) return Jni.strerror() ?: "Unknown error" else return null
    }

    fun pull(): String? {
        val r = Jni.pull(repoStr)
        Log.v("Pull done: $r")
        if (r != 0) return Jni.strerror() ?: "Unknown error" else return null
    }

    fun log(): List<CommitInfo> {
        return Jni.log(repoStr).map { logStr -> CommitInfo(logStr) }
    }
}
