package kafva.kage.data

import java.io.File
import javax.inject.Inject

class PwNodeRepository @Inject constructor() {
    lateinit var rootNode: PwNode

    fun load(rootPath: File) {
        rootNode = PwNode(rootPath, listOf())
    }
}
