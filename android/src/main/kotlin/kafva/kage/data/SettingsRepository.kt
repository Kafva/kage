package kafva.kage.data

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.edit
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.collectLatest
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import kafva.kage.Log


data class Settings(
    val remoteAddress: String,
    val remoteRepoPath: String
)

/// https://github.com/Kotlin-Android-Open-Source/DataStore-sample
@Singleton
class SettingsRepository @Inject constructor(
    private val dataStore: DataStore<Preferences>,
) {
    private object Keys {
        val remoteAddress = stringPreferencesKey("remoteAddress")
        val remoteRepoPath = stringPreferencesKey("remoteRepoPath")
    }

    private inline val Preferences.remoteAddress
        get() = this[Keys.remoteAddress] ?: ""

    private inline val Preferences.remoteRepoPath
        get() = this[Keys.remoteRepoPath] ?: ""


    suspend fun updateSettings(s: Settings) {
        dataStore.edit {
            it[Keys.remoteAddress] = s.remoteAddress
            it[Keys.remoteRepoPath] = s.remoteRepoPath
        }
        Log.i("Updated settings: ${s.remoteAddress}/${s.remoteRepoPath}")
    }

    val flow: Flow<Settings> =
        dataStore.data
            .catch {
                if (it is IOException) {
                    emit(emptyPreferences())
                } else {
                    throw it
                }
            }.map { preferences ->
                Settings(
                    remoteAddress = preferences.remoteAddress,
                    remoteRepoPath = preferences.remoteRepoPath,
                )
            }.distinctUntilChanged()
}
