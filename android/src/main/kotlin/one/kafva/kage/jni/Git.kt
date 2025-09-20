package one.kafva.kage.jni

object Git {
    external fun clone(
        url: String,
        into: String,
    ): Int

    external fun setUser(
        repoPath: String,
        username: String,
    ): Int

    external fun stage(
        repoPath: String,
        relativePath: String,
    ): Int

    external fun reset(repoPath: String): Int

    external fun commit(
        repoPath: String,
        message: String,
    ): Int

    external fun log(localRepoPath: String): Array<String>?

    external fun strerror(): String?
}
