package kafva.kage.types

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/**
 * Create an object from a newline separated string on the format
 * `<epoch>\n<oid>\n<summary>`
 */
class CommitInfo(
    str: String,
) {
    val date: String
    val revision: String
    val summary: String

    init {
        val spl = str.split("\n")
        date =
            Instant
                .ofEpochSecond(spl[0].toLong())
                .atZone(ZoneId.systemDefault())
                .format(
                    DateTimeFormatter.ofPattern("MMM d HH:mm:ss yyyy"),
                )
        revision = spl[1]
        summary = spl[2]
    }
}
