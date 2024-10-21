package kafva.kage.data

import kafva.kage.Log
import kafva.kage.types.CommitInfo
import kafva.kage.types.PwNode
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import javax.inject.Singleton
import kafva.kage.jni.Git as Jni

class GitException(
    message: String,
) : Exception(message)

// Keep mutable state flows private, and expose non-modifiable state-flows
@Singleton
class GitRepository
    @Inject
    constructor(
        private val appRepository: AppRepository,
    ) {
        private val repoStr = appRepository.localRepo.toPath().toString()
        private val rootNode = MutableStateFlow<PwNode?>(null)

        private val _query = MutableStateFlow("")
        val query: StateFlow<String> = _query

        private val _searchMatches = MutableStateFlow<List<PwNode>>(listOf())
        val searchMatches: StateFlow<List<PwNode>> = _searchMatches

        private val _passwordCount = MutableStateFlow(0)
        val passwordCount: StateFlow<Int> = _passwordCount

        /** (Re)load password tree from disk */
        fun setup() {
            rootNode.value = PwNode(appRepository.localRepo, listOf())
            // Populate the search result with all nodes
            _searchMatches.value =
                rootNode.value?.findChildren(_query.value) ?: listOf()
            // Update the password count
            _passwordCount.value = rootNode.value?.passwordCount() ?: 0
        }

        /** Reclone from URL */
        @Throws(GitException::class)
        fun clone(
            remoteAddress: String,
            remoteRepoPath: String,
            localClone: Boolean,
        ) {
            appRepository.localRepo.deleteRecursively()

            val url =
                when (localClone) {
                    true -> "file://$remoteRepoPath"
                    else -> "git://$remoteAddress/$remoteRepoPath"
                }
            Log.d("Cloning $url into ${appRepository.localRepo}...")

            val r = Jni.clone(url, repoStr)
            if (r != 0) {
                raiseError()
            } else {
                Log.d("Clone ok")
                setup()
            }
        }

        fun log(): List<CommitInfo> =
            Jni.log(repoStr).map { logStr -> CommitInfo(logStr) }

        fun updateMatches(text: String) {
            Log.d("Updated query: ${query.value}")
            _query.value = text.lowercase()
            _searchMatches.value =
                rootNode.value?.findChildren(query.value) ?: listOf()
        }

        @Throws(GitException::class)
        private fun raiseError() {
            val message = Jni.strerror()
            if (message != null) {
                throw GitException(message)
            } else {
                throw GitException("Unknown error")
            }
        }
    }
