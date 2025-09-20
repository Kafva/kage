package one.kafva.kage.data

import one.kafva.kage.LOCAL_REPO_NAME
import java.io.File
import javax.inject.Singleton

@Singleton
class AppDataSource(
    val isDebug: Boolean,
    val filesDir: File,
) {
    val localRepo: File = File("$filesDir/${LOCAL_REPO_NAME}")
}
