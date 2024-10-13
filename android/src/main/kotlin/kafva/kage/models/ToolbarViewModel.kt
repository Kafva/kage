package kafva.kage.models

import javax.inject.Inject
import dagger.hilt.android.lifecycle.HiltViewModel
import androidx.lifecycle.ViewModel
import kafva.kage.data.RuntimeSettingsRepository
import kafva.kage.data.AppRepository
import kafva.kage.data.GitRepository

@HiltViewModel
class ToolbarViewModel @Inject constructor(
    val appRepository: AppRepository,
    val gitRepository: GitRepository,
    val runtimeSettingsRepository: RuntimeSettingsRepository,
) : ViewModel() {}
