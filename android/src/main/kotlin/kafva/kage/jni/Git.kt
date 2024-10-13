package kafva.kage.jni

object Git {
    external fun clone(
        url: String,
        into: String,
    ): Int

    external fun log(localRepoPath: String): Array<String>

    external fun strerror(): String?
}
