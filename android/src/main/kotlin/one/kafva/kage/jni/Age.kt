package one.kafva.kage.jni

object Age {
    external fun unlockIdentity(
        encryptedIdentity: String,
        password: String,
    ): Int

    external fun lockIdentity(): Int

    external fun decrypt(encryptedPath: String): String?

    external fun strerror(): String?
}
