package kafva.kage.data

import java.io.File

data class PwNode(
    private val path: File,
    private var children: List<PwNode>,
) {
    private companion object {
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
    }

    val name = path.getName()

    // / Recursively load the nodes under the current path
    init {
        children = PwNode.loadChildren(path)
    }
}
