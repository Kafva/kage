package kafva.kage

class Git {
    external fun clone(
        url: String,
        into: String,
    ): Int

    external fun pull(repoPath: String): Int

    external fun log(repoPath: String): String

    external fun strerror(): String
}