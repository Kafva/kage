package kafva.kage.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.AlertDialog
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import kafva.kage.Log
import kafva.kage.data.GitRepository
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import kafva.kage.types.CommitInfo
import kafva.kage.G
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class HistoryViewModel @Inject constructor(
    val gitRepository: GitRepository
) : ViewModel() {}

@Composable
fun HistoryView(
    viewModel: HistoryViewModel = hiltViewModel()
) {
    LazyColumn(modifier = G.containerModifier) {
        viewModel.gitRepository.log().forEach { log ->
            item {
                ListItem(
                    headlineContent = { Text(text = log.summary,
                                             fontSize = 14.sp,
                                             maxLines = 1,
                                             overflow = TextOverflow.Ellipsis) },
                    leadingContent = {
                        Text(log.date, fontSize = 12.sp,
                             color = Color.Gray,
                             maxLines = 1,
                             overflow = TextOverflow.Ellipsis)
                    },
                    modifier = Modifier.padding(bottom = 10.dp).clip(RoundedCornerShape(50)),
                    colors = ListItemDefaults.colors(
                      containerColor = MaterialTheme.colorScheme.surfaceContainer,
                    )
                )
            }
        }
    }
}
