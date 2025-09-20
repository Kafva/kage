package one.kafva.kage.di

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import one.kafva.kage.data.AgeDataSource
import one.kafva.kage.data.AppDataSource
import one.kafva.kage.data.GitDataSource
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppContextModule {
    private val Context.userPreference by preferencesDataStore(
        name = "preference",
    )

    /**
     * https://github.com/mbobiosio/AppFirstLaunch-Hilt-DataStore
     * Dagger needs a way to construct every type that is provided in an
     * @Inject constructor(). This function provides dagger with a way to
     * provide a DataStore<Preferences> object.
     */
    @Provides
    @Singleton
    fun provideDataStore(
        @ApplicationContext context: Context,
    ): DataStore<Preferences> = context.userPreference

    @Provides
    @Singleton
    fun provideGitContext(
        @ApplicationContext appContext: Context,
    ): GitDataSource =
        GitDataSource(
            provideAppContext(appContext),
        )

    @Provides
    @Singleton
    fun provideAgeContext(
        @ApplicationContext appContext: Context,
    ): AgeDataSource =
        AgeDataSource(
            provideAppContext(appContext),
        )

    @Provides
    @Singleton
    fun provideAppContext(
        @ApplicationContext appContext: Context,
    ): AppDataSource {
        val name = appContext.packageName
        val pInfo: PackageInfo =
            appContext.packageManager.getPackageInfo(
                name,
                0,
            )
        val isDebug =
            pInfo.applicationInfo?.flags?.and(
                ApplicationInfo.FLAG_DEBUGGABLE,
            ) !=
                0

        val filesDir = appContext.filesDir

        return AppDataSource(isDebug, filesDir)
    }
}
