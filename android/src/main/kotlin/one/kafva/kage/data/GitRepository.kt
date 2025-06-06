package one.kafva.kage.data

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import one.kafva.kage.Log
import one.kafva.kage.types.CommitInfo
import one.kafva.kage.types.PwNode
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton
import one.kafva.kage.jni.Git as Jni

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
            val node = PwNode(appRepository.localRepo, listOf())
            // Load child nodes recursively
            node.loadChildren()
            rootNode.value = node
            // Populate the search result with all nodes
            _searchMatches.value =
                rootNode.value?.findChildren(_query.value) ?: listOf()
            // Update the password count
            _passwordCount.value = rootNode.value?.passwordCount() ?: 0
        }

        /** Reclone from URL */
        @Throws(GitException::class)
        fun clone(url: String) {
            appRepository.localRepo.deleteRecursively()
            Log.d("Cloning $url into ${appRepository.localRepo}...")

            // If a file:/// URL is provided, simply copy from that location.
            // Cloning from file:/// paths generally does not work due to
            // the default `safe.directory` configuration in git.
            if (url.startsWith("file://")) {
                val srcdir = File(url.removePrefix("file://"))
                srcdir
                    .copyRecursively(appRepository.localRepo, true, onError = {
                        _,
                        e,
                        ->
                        throw GitException(e.message ?: "Unknown error")
                    })
            } else {
                val r = Jni.clone(url, repoStr)
                if (r != 0) {
                    raiseError()
                }
            }

            Log.d("Clone ok")
            setup()
        }

        fun log(): List<CommitInfo> =
            Jni.log(repoStr)?.map { logStr -> CommitInfo(logStr) } ?: listOf()

        fun updateMatches(text: String) {
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
