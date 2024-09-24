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
import kafva.kage.data.PwNode
import kafva.kage.Log
import kafva.kage.data.GitRepository

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
}
