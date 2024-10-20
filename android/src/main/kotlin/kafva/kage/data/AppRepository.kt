package kafva.kage.data

import kafva.kage.G
import java.io.File
import javax.inject.Singleton

@Singleton
class AppRepository constructor(
    val versionName: String,
    val filesDir: File,
) {
    val localRepo: File = File("${filesDir}/${G.LOCAL_REPO_NAME}")
}
