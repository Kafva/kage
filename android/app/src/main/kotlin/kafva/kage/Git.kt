package kafva.kage

object Git {
    external fun clone(
        url: String,
        into: String,
    ): Int

    external fun pull(repoPath: String): Int

    external fun log(repoPath: String): Array<String>

    external fun strerror(): String?
}
