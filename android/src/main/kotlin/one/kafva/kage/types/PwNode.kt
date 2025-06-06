package one.kafva.kage.types

import java.io.File

data class PwNode(
    private val path: File,
    var children: List<PwNode>,
) {
    companion object {
        fun fromRoutePath(serialisedNodePath: String): String =
            serialisedNodePath.replace("|", "/")

        fun prettyName(nodePath: String): String =
            nodePath.split("/").last().removeSuffix(".age")
    }

    val name = path.getName().removeSuffix(".age")
    private val isPassword = path.getName().endsWith(".age")
    private val pathString = path.toPath().toString()

    fun toRoutePath(filesDir: File): String =
        pathString.removePrefix("${filesDir.path}/").replace("/", "|")

    /**
     * Recursively load the nodes under the current path, needs to be called
     * explicitly after creating an object.
     */
    fun loadChildren() {
        if (!path.isDirectory()) {
            return
        }

        val mutableChildren: MutableList<PwNode> = mutableListOf()

        path.listFiles()?.forEach {
            val name = it.getName() ?: ""
            if (name != "" && !name.startsWith(".")) {
                val child = PwNode(it, listOf())
                child.loadChildren()
                mutableChildren.add(child)
            }
        }

        children = mutableChildren.toList()
    }

    /** Predicate should be provided in lowercase! */
    fun findChildren(predicate: String): List<PwNode> {
        // Include all of the children if there is no query
        if (predicate.isEmpty()) {
            return children
        }

        val matches: MutableList<PwNode> = mutableListOf()

        // If the parent does not match the predicate, check each child
        for (child in children) {
            if (child.name.lowercase().contains(predicate)) {
                // Include everything beneath a matching child
                matches.add(child)
                continue
            }

            // Check children recursively if the current child was not a match
            val childMatches = child.findChildren(predicate)

            // Include the child with the subset of the child nodes that match the query
            if (childMatches.isNotEmpty()) {
                val subsetChild = PwNode(child.path, childMatches.toList())
                matches.add(subsetChild)
            }
        }

        return matches.toList()
    }

    /** Recursive count of children */
    fun passwordCount(): Int {
        val childCount = children.count { it.isPassword }
        return childCount + children.sumOf { it.passwordCount() }
    }
}
