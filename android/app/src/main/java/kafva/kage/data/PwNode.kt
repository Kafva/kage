package kafva.kage

import java.nio.file.Path

data class PwNode constructor(
    private val path: Path,
    private val children: List<PwNode>,
) {
    val name = path.fileName
}
