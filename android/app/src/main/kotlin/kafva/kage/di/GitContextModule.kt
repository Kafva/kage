package kafva.kage.di

import android.content.Context
import android.content.pm.PackageInfo
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton
import java.io.File
import javax.inject.Inject
import kafva.kage.data.PwNode
import kafva.kage.Log
import kafva.kage.data.GitRepository

class VersionRepository constructor(val versionName: String) {}

@Module
@InstallIn(SingletonComponent::class)
object GitContextModule {

    @Provides
    @Singleton
    fun provideGitContext(
        @ApplicationContext appContext: Context
    ): GitRepository = GitRepository(
        appContext.filesDir.path
    )


    @Provides
    @Singleton
    fun provideVersion(
        @ApplicationContext appContext: Context
    ): VersionRepository {
        val name = appContext.getPackageName()
        val pkgManager = appContext.getPackageManager()
        val pInfo: PackageInfo = pkgManager.getPackageInfo(name, 0)
        return VersionRepository(pInfo.versionName ?: "Unknown")
    }

}
