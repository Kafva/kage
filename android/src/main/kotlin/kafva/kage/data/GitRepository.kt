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
import kafva.kage.types.PwNode
import kafva.kage.data.AppRepository
import kafva.kage.Log
import kafva.kage.jni.Git as Jni
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kafva.kage.types.CommitInfo

class GitException(message: String): Exception(message)

/// Keep mutable state flows private, and expose non-modifiable state-flows
@Singleton
class GitRepository @Inject constructor(private val appRepository: AppRepository) {
    val repoStr = appRepository.localRepo.toPath().toString()

    private val _query = MutableStateFlow("")
    val query: StateFlow<String> = _query

    private val _searchMatches = MutableStateFlow<List<PwNode>>(listOf())
    val searchMatches: StateFlow<List<PwNode>> = _searchMatches

    private val _rootNode = MutableStateFlow<PwNode?>(null)
    val rootNode: StateFlow<PwNode?> = _rootNode

    private val _passwordCount = MutableStateFlow<Int>(0)
    val passwordCount: StateFlow<Int> = _passwordCount

    /// (Re)load password tree from disk
    fun setup() {
        _rootNode.value = PwNode(appRepository.localRepo, listOf())
        // Populate the search result with all nodes
        _searchMatches.value = rootNode.value?.findChildren(_query.value) ?: listOf()
        // Update the password count
        _passwordCount.value = _rootNode.value?.passwordCount() ?: 0
    }

    /// Reclone from URL
    @Throws(GitException::class)
    suspend fun clone(remoteAddress: String, remoteRepoPath: String) {
        Log.v("Recloning into ${appRepository.localRepo}...")
        appRepository.localRepo.deleteRecursively()

        val url = "git://${remoteAddress}/${remoteRepoPath}"
        val r = Jni.clone(url, repoStr)
        if (r != 0) {
            raiseError()
        }
        else {
            Log.d("Clone ok")
            setup()
        }
    }

    fun log(): List<CommitInfo> {
        return Jni.log(repoStr).map { logStr -> CommitInfo(logStr) }
    }

    fun updateMatches(text: String) {
        Log.d("Updated query: ${query.value}")
        _query.value = text.lowercase()
        _searchMatches.value = rootNode.value?.findChildren(query.value) ?: listOf()
    }

    @Throws(GitException::class)
    private fun raiseError() {
        val message = Jni.strerror()
        if (message != null) {
            throw GitException(message)
        }
        else {
            throw GitException("Unknown error")
        }
    }
}
