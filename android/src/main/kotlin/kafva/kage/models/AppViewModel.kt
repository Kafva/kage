package kafva.kage.models

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.launch
import java.io.File
import java.time.Instant
import javax.inject.Inject
import javax.inject.Singleton
import kafva.kage.Log
import kafva.kage.G
import kotlinx.coroutines.flow.stateIn
import kafva.kage.types.PwNode
import kotlin.text.lowercase
import kafva.kage.data.AppRepository
import kafva.kage.data.AgeRepository
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.LocalLifecycleOwner

@HiltViewModel
class AppViewModel @Inject constructor(
    val appRepository: AppRepository,
    val ageRepository: AgeRepository,
) : ViewModel() {}
