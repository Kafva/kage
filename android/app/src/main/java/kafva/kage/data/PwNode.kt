package kafva.kage.data

import java.io.File

data class PwNode (
    private val path: File,
    private var children: List<PwNode>,
) {
    val name = path.getName()

    init {
        if (path.isDirectory()) {
            val mutableChildren: MutableList<PwNode> = mutableListOf()

            for (f in path.listFiles()) {
                val childPath: File = f!!
                val name = childPath.getName() ?: ""

                if (name == "" || name.startsWith(".")) {
                    continue
                }
                val child: PwNode = PwNode(childPath, listOf())
                mutableChildren.add(child)
            }

            children = mutableChildren.toList()
        }
    }
}
