package kafva.kage.data

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
import javax.inject.Inject
import javax.inject.Singleton
import kafva.kage.Log
import kotlinx.coroutines.flow.stateIn
import kafva.kage.data.PwNode
import kotlin.text.lowercase
import kafva.kage.data.AppRepository

@HiltViewModel
class AppViewModel @Inject constructor(
    val appRepository: AppRepository,
) : ViewModel() {}
