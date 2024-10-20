package kafva.kage.types

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/// Create an object from a newline seperated string on the format
/// `<epoch>\n<oid>\n<summary>`
class CommitInfo (str: String) {
    val date: String
    val summary: String

    init {
        val spl = str.split("\n")
        date = Instant.ofEpochSecond(spl[0].toLong())
                      .atZone(ZoneId.systemDefault())
                      .format(DateTimeFormatter.ofPattern("MMM d HH:mm:ss yyyy"))
        summary = spl[2]
    }
}

