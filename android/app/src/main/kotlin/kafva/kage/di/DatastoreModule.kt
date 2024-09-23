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

/// https://github.com/mbobiosio/AppFirstLaunch-Hilt-DataStore
/// Dagger needs a way to construct every type that is provided in an @Inject constructor()
/// This module provides dagger with a way to provide a DataStore<Preferences>
/// object.
@Module
@InstallIn(SingletonComponent::class)
object DatastoreModule {

    private val Context.userPreference by preferencesDataStore(name = "preference")

    @Provides
    @Singleton
    fun provideDataStore(
        @ApplicationContext context: Context
    ): DataStore<Preferences> = context.userPreference
}
