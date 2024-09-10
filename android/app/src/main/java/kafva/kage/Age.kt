package kafva.kage

class Age {
    external fun unlockIdentity(
        encryptedIdentity: String,
        passphrase: String,
    ): Int

    external fun lockIdentity(): Int

    external fun decrypt(encryptedPath: String): String

    external fun strerror(): String
}
