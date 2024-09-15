package kafva.kage.data

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import java.io.IOException

data class Settings(
    val remoteAddress: String,
)

// / https://github.com/Kotlin-Android-Open-Source/DataStore-sample
class SettingsRepository(
    private val dataStore: DataStore<Preferences>,
) {
    private object Keys {
        val remoteAddress = stringPreferencesKey("remote_address")
    }

    private inline val Preferences.remoteAddress
        get() = this[Keys.remoteAddress] ?: ""

    val settings: Flow<Settings> =
        dataStore.data
            .catch {
                // throws an IOException when an error is encountered when reading data
                if (it is IOException) {
                    emit(emptyPreferences())
                } else {
                    throw it
                }
            }.map { preferences ->
                Settings(
                    remoteAddress = preferences.remoteAddress,
                )
            }.distinctUntilChanged()
}
