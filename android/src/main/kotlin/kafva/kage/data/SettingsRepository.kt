package kafva.kage.data

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringPreferencesKey
import kafva.kage.G
import kafva.kage.Log
import kafva.kage.types.Settings
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

// https://github.com/Kotlin-Android-Open-Source/DataStore-sample
@Singleton
class SettingsRepository
    @Inject
    constructor(
        private val dataStore: DataStore<Preferences>,
    ) {
        private object Keys {
            val cloneUrl = stringPreferencesKey("cloneUrl")
        }

        // https://developer.android.com/studio/run/emulator-networking
        private inline val Preferences.cloneUrl
            get() =
                this[Keys.cloneUrl]
                    ?: (
                        if (G.isEmulator) {
                            "git://10.0.2.2/james.git"
                        } else {
                            "file:///data/user/0/kafva.kage/files/kage-store.git"
                        }
                    )

        suspend fun updateSettings(s: Settings) {
            dataStore.edit {
                it[Keys.cloneUrl] = s.cloneUrl
            }
            Log.d("Updated settings: ${s.cloneUrl}")
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
                        cloneUrl = preferences.cloneUrl,
                    )
                }.distinctUntilChanged()
    }
