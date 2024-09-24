package kafva.kage.data

import java.io.File
import javax.inject.Inject
// import kafva.kage.di.GitContext

class PwNodeRepository @Inject constructor(
//  private val gitContext: GitContext
) {
    lateinit var rootNode: PwNode

    fun load(rootPath: File) {
        rootNode = PwNode(rootPath, listOf())
    }
}
