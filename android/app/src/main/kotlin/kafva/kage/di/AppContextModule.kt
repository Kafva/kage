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
import kafva.kage.data.AppRepository


@Module
@InstallIn(SingletonComponent::class)
object AppContextModule {

    private val Context.userPreference by preferencesDataStore(name = "preference")

    @Provides
    @Singleton
    fun provideGitContext(
        @ApplicationContext appContext: Context
    ): GitRepository = GitRepository(
        provideAppContext(appContext)
    )


    @Provides
    @Singleton
    fun provideAppContext(
        @ApplicationContext appContext: Context
    ): AppRepository {
        val name = appContext.getPackageName()
        val pkgManager = appContext.getPackageManager()
        val pInfo: PackageInfo = pkgManager.getPackageInfo(name, 0)
        val versionName = pInfo.versionName ?: "Unknown"

        val filesDir = appContext.filesDir

        return AppRepository(versionName, filesDir)
    }

    /// https://github.com/mbobiosio/AppFirstLaunch-Hilt-DataStore
    /// Dagger needs a way to construct every type that is provided in an
    /// @Inject constructor(). This function provides dagger with a way to
    /// provide a DataStore<Preferences> object.
    @Provides
    @Singleton
    fun provideDataStore(
        @ApplicationContext context: Context
    ): DataStore<Preferences> = context.userPreference

}
