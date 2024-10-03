package kafva.kage.ui.views

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
import androidx.compose.material3.MaterialTheme
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
import kafva.kage.types.Screen
import kafva.kage.Log
import kafva.kage.data.SettingsViewModel
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Row
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.focus.FocusDirection
import androidx.navigation.NavHostController
import android.content.pm.PackageInfo
import androidx.compose.material3.ButtonDefaults

@Composable
fun SettingsView(
    navController: NavHostController,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val focusManager = LocalFocusManager.current
    val keyboardController = LocalSoftwareKeyboardController.current

    val openAlertDialog = remember { mutableStateOf(false) }
    val remoteAddress = remember { mutableStateOf("") }
    val repoPath = remember { mutableStateOf("") }

    Column(modifier = Modifier.padding(top = 10.dp)) {
        TextField(
            value = remoteAddress.value,
            leadingIcon = { Icon(Icons.Filled.Home, "Remote address") },
            label = { Text("Remote address") },
            onValueChange = {
                remoteAddress.value = it
            },

            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done, keyboardType = KeyboardType.Text),
            keyboardActions = KeyboardActions(
                onDone = {
                    val newSettings = Settings(remoteAddress.value, repoPath.value)
                    viewModel.updateSettings(newSettings)
                    focusManager.moveFocus(FocusDirection.Down)
                }
            ),
        )

        TextField(
            value = repoPath.value,
            leadingIcon = { Icon(Icons.Filled.Person, "Repository") },
            label = { Text("Repository") },
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
                    focusManager.moveFocus(FocusDirection.Down)
                    // focusManager.clearFocus()
                    // keyboardController?.hide()
                    // focusManager.clearFocus()
                }
            ),
        )

        Text("Version: ${viewModel.versionRepository.versionName}",
             modifier = Modifier.padding(top = 4.dp),
             fontSize = 12.sp,
             color = Color.Gray)

        TextButton(
            onClick = {
                openAlertDialog.value = true
            },
            modifier = Modifier.padding(top = 4.dp)
        ) {
            Text("Reset password repository")
        }

        if (openAlertDialog.value) {
            AlertDialog(
                icon = {
                    Icon(Icons.Filled.Warning,
                         contentDescription = "")
                },
                title = {
                    Text(text = "Are you sure?")
                },
                text = {
                    Text("This operation will delete the local checkout")
                },
                onDismissRequest = {
                    openAlertDialog.value = false
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            viewModel.clone()
                            openAlertDialog.value = false
                        }
                    ) {
                        Text("Yes", color = Color.Red)
                    }
                },
                dismissButton = {
                    TextButton(
                        onClick = {
                            openAlertDialog.value = false
                        }
                    ) {
                        Text("No")
                    }
                },
            )
        }

        TextButton(
            onClick = {
                navController.navigate(Screen.History.route)
            },
            modifier = Modifier.padding(top = 4.dp)
        ) {
            Text("History")
        }


        LaunchedEffect(Unit) {
            // Fill the textfields with the current configuration from the
            // datastore when the view appears.
            viewModel.settingsRepository.flow.collect { s ->
                remoteAddress.value = s.remoteAddress
                repoPath.value = s.repoPath
            }
        }
    }
}

