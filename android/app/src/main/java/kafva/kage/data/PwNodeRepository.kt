package kafva.kage.data

import java.io.File
import javax.inject.Inject

class PwNodeRepository
    @Inject
    constructor() {
        lateinit var pwNodeStore: PwNode

        fun load(rootPath: File) {
            pwNodeStore = PwNode(rootPath, listOf())
        }
    }
