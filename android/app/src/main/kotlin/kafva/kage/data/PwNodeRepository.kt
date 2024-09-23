package kafva.kage.data

import java.io.File
import javax.inject.Inject
// import android.content.Context

class PwNodeRepository @Inject constructor(
  //  private val appContext: Context
) {
    lateinit var rootNode: PwNode

    fun load(rootPath: File) {
        rootNode = PwNode(rootPath, listOf())
    }
}
