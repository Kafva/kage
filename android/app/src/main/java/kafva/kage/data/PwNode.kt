@file:Suppress("ktlint:standard:no-wildcard-imports")

package kafva.kage

import java.nio.file.Path
import kotlin.io.path.*

data class PwNode(
    val path: Path,
    var children: List<PwNode>,
) {
    init {
        if (path.isDirectory()) {
            val mutableChildren: MutableList<PwNode> = mutableListOf()

            for (childPath: Path in path.listDirectoryEntries()) {
                if (childPath.name.startsWith(".")) {
                    continue
                }
                val child: PwNode = PwNode(childPath, listOf())
                mutableChildren.add(child)
            }

            children = mutableChildren.toList()
        }
    }
}
