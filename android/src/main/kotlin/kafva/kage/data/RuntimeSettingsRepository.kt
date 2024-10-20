package kafva.kage.data

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import javax.inject.Singleton

/** Singleton to make sure all view models use the same backing object */
@Singleton
class RuntimeSettingsRepository
    @Inject
    constructor() {
        private val _expandRecursively = MutableStateFlow(false)
        val expandRecursively: StateFlow<Boolean> = _expandRecursively

        fun setExpandRecursively(value: Boolean) {
            _expandRecursively.value = value
        }

        fun toggleExpandRecursively() {
            _expandRecursively.value = !_expandRecursively.value
        }
    }
