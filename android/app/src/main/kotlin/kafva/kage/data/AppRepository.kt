package kafva.kage.data

import java.io.File


class AppRepository constructor(
    val versionName: String,
    val filesDir: File,
) {
    val localRepoName = "git-adc83b19e"
    val localRepo: File = File("${filesDir}/${localRepoName}")
}

