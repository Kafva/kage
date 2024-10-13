package kafva.kage.data

import java.io.File
import kafva.kage.jni.Age
import kafva.kage.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import dagger.hilt.components.SingletonComponent
import java.time.Instant
import java.util.Date
import javax.inject.Singleton

@Singleton
class AppRepository constructor(
    val versionName: String,
    val filesDir: File,
) {
    val localRepoName = "git-adc83b19e"
    val localRepo: File = File("${filesDir}/${localRepoName}")
}
