package kafva.kage.data

import javax.inject.Inject
import dagger.hilt.android.lifecycle.HiltViewModel
import androidx.lifecycle.ViewModel
import kafva.kage.data.RuntimeSettingsRepository

@HiltViewModel
class ToolbarViewModel @Inject constructor(
    val gitRepository: GitRepository,
    val runtimeSettingsRepository: RuntimeSettingsRepository,
) : ViewModel() {}
