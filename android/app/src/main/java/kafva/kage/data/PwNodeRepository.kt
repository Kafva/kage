package kafva.kage.data

// import dagger.Module
// import dagger.Provides
// import dagger.hilt.InstallIn
// import dagger.hilt.components.SingletonComponent
import java.io.File
import javax.inject.Inject

// @Module
// @InstallIn(SingletonComponent::class)
class PwNodeRepository
    @Inject
    constructor() {
        lateinit var pwNodeStore: PwNode

        fun load(rootPath: File) {
            pwNodeStore = PwNode(rootPath, listOf())
        }
    }
