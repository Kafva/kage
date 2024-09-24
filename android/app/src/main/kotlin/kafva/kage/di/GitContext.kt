package kafva.kage.di

import android.content.Context
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

class GitContext constructor(val filesDir: String) {
    val localRepoName = "git-adc83b19e"
    val repoPath: File = File("${filesDir}/${localRepoName}")
}

@Module
@InstallIn(SingletonComponent::class)
object GitContextModule {


    @Provides
    @Singleton
    fun provideGitContext(
        @ApplicationContext appContext: Context
    ): GitContext = GitContext(
        appContext.filesDir.path
    )
}
