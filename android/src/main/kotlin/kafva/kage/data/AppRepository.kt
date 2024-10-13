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
import kafva.kage.G

@Singleton
class AppRepository constructor(
    val versionName: String,
    val filesDir: File,
) {
    val localRepo: File = File("${filesDir}/${G.LOCAL_REPO_NAME}")
}
