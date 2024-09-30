package kafva.kage.ui.views

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextFieldDefaults
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
import kafva.kage.data.Settings
import kafva.kage.Log
import kafva.kage.data.SettingsViewModel
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.focus.FocusDirection


@Composable
fun SettingsView(
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val focusManager = LocalFocusManager.current
    val keyboardController = LocalSoftwareKeyboardController.current

    val emptySettings = Settings("10.0.2.2", "james.git") // TODO
    val settings = viewModel.settingsRepository.flow.collectAsState(emptySettings)
    val remoteAddress = remember { mutableStateOf(settings.value.remoteAddress) }
    val repoPath = remember { mutableStateOf(settings.value.repoPath) }

    Column {
        TextField(
            value = remoteAddress.value,
            leadingIcon = { Icon(Icons.Filled.PlayArrow, "Remote address") },
            //placeholder = { Text(settings.value.remoteAddress) },
            label = { Text("Remote address") },
            onValueChange = {
                remoteAddress.value = it
            },

            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done, keyboardType = KeyboardType.Text),
            keyboardActions = KeyboardActions(
                onDone = {
                    // val newSettings = Settings(remoteAddress.value, repoPath.value)
                    // viewModel.updateSettings(newSettings)
                    // keyboardController?.hide()
                    focusManager.moveFocus(FocusDirection.Down)
                }
            ),
        )

        TextField(
            value = repoPath.value,
            leadingIcon = { Icon(Icons.Filled.Person, "Repository") },
            label = { Text("Repository") },
            //placeholder = { Text(settings.value.repoPath) },
            onValueChange = {
                repoPath.value = it
            },
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done, keyboardType = KeyboardType.Text),
            keyboardActions = KeyboardActions(
                onDone = {
                    // https://developer.android.com/studio/run/emulator-networking
                    // git://10.0.2.2:9418/james.git
                    val newSettings = Settings(remoteAddress.value, repoPath.value)
                    viewModel.updateSettings(newSettings)
                    // focusManager.clearFocus()
                    keyboardController?.hide()
                    focusManager.moveFocus(FocusDirection.Down)
                }
            ),
        )

        TextButton(
            onClick = {
                viewModel.clone()
            },
            modifier = Modifier.padding(top = 4.dp)
        ) {
            Text("Reset password repository")
        }

        LaunchedEffect(Unit) {
            Log.d("Launched view!")
        }
    }
}

