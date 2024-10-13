package kafva.kage.types

import java.io.File

data class PwNode(
    private val path: File,
    var children: List<PwNode>,
) {
    companion object {

        private fun loadChildren(path: File): List<PwNode> {
            if (!path.isDirectory()) {
                return listOf()
            }

            val mutableChildren: MutableList<PwNode> = mutableListOf()

            path.listFiles()?.forEach {
                val name = it.getName() ?: ""
                if (name != "" && !name.startsWith(".")) {
                    val child: PwNode = PwNode(it, listOf())
                    mutableChildren.add(child)
                }
            }

            return mutableChildren.toList()
        }

        fun fromRoutePath(serialisedNodePath: String): String {
            return serialisedNodePath.replace("|", "/")
        }

        fun prettyName(nodePath: String): String {
            return nodePath.split("/").last().removeSuffix(".age")
        }
    }

    val name = path.getName().removeSuffix(".age")
    val pathString = path.toPath().toString()

    fun toRoutePath(filesDir: File): String {
        return pathString.removePrefix("${filesDir.path}/").replace("/", "|")
    }

    /// Recursively load the nodes under the current path
    init {
        children = PwNode.loadChildren(path)
    }

    /// Predicate should be provided in lowercase!
    fun findChildren(predicate: String): List<PwNode> {
        // Include all of the children if there is no query
        if (predicate.isEmpty()) {
            return children
        }

        var matches: MutableList<PwNode> = mutableListOf()

        // If the parent does not match the predicate, check each child
        for (child in children) {
            if (child.name.lowercase().contains(predicate)) {
                // Include everything beneath a matching child
                matches.add(child)
                continue
            }

            // Check children recursively if the current child was not a match
            var childMatches = child.findChildren(predicate)

            // Include the child with the subset of the child nodes that match the query
            if (!childMatches.isEmpty()) {
                var subsetChild = PwNode(child.path, childMatches.toList())
                matches.add(subsetChild)
            }
        }

        return matches.toList()
    }
}
