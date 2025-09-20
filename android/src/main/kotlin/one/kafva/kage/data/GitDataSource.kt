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
class GitDataSource
    @Inject
    constructor(
        private val appDataSource: AppDataSource,
    ) {
        private val repoStr = appDataSource.localRepo.toPath().toString()
        private val rootNode = MutableStateFlow<PwNode?>(null)

        private val _query = MutableStateFlow("")
        val query: StateFlow<String> = _query

        private val _searchMatches = MutableStateFlow<List<PwNode>>(listOf())
        val searchMatches: StateFlow<List<PwNode>> = _searchMatches

        private val _passwordCount = MutableStateFlow(0)
        val passwordCount: StateFlow<Int> = _passwordCount

        /** (Re)load password tree from disk */
        fun setup() {
            val node = PwNode(appDataSource.localRepo, listOf())
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
            appDataSource.localRepo.deleteRecursively()
            Log.d("Cloning $url into ${appDataSource.localRepo}...")

            // If a file:/// URL is provided, simply copy from that location.
            // Cloning from file:/// paths generally does not work due to
            // the default `safe.directory` configuration in git.
            if (url.startsWith("file://")) {
                val srcdir = File(url.removePrefix("file://"))
                srcdir
                    .copyRecursively(appDataSource.localRepo, true, onError = {
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

            // Use the repo name as the username
            val username = appDataSource.localRepo.nameWithoutExtension
            val repoPath = appDataSource.localRepo.toPath().toString()
            Jni.setUser(repoPath, username)
            Log.d("Set user.name=$username")

            setup()
        }

        /** Delete the provided `node` from the tree and commit the change,
         * resets to the local HEAD on error.
         */
        @Throws(GitException::class)
        fun remove(node: PwNode) {
            var r: Int
            val path =
                appDataSource.localRepo.toPath()
                    ?: throw GitException("No root node set")
            val repoPath = path.toString()

            if (!node.delete()) {
                Jni.reset(repoPath)
                throw GitException("Failed to remove: '${node.name}'")
            }

            r = Jni.stage(repoPath, node.name)
            if (r != 0) {
                Jni.reset(repoPath)
                raiseError()
            }

            r = Jni.commit(repoPath, "Removed ${node.name}")
            if (r != 0) {
                Jni.reset(repoPath)
                raiseError()
            }
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
