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

class GitRepository @Inject constructor(val filesDir: String) {
    var rootNode: PwNode? = null
    val localRepoName = "git-adc83b19e"
    val repoPath: File = File("${filesDir}/${localRepoName}")

    /// Load password tree recursively
    fun setup() {
        rootNode = PwNode(repoPath, listOf())
    }

    /// Reclone from URL
    fun clone(url: String): String? {
        Log.v("Recloning into $repoPath...")
        repoPath.deleteRecursively()

        val r = Jni.clone(url, repoPath.toPath().toString())
        Log.v("Clone done: $r")
        if (r != 0) return Jni.strerror() ?: "Unknown error" else return null
    }

    fun pull(): String? {
        val r = Jni.pull(repoPath.toPath().toString())
        Log.v("Pull done: $r")
        if (r != 0) return Jni.strerror() ?: "Unknown error" else return null
    }
}
