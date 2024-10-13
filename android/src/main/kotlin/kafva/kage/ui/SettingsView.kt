package kafva.kage.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.KeyboardActionScope
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material3.Card
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
import kafva.kage.types.Settings
import kafva.kage.types.Screen
import kafva.kage.Log
import kafva.kage.models.SettingsViewModel
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Row
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.Alignment
import androidx.navigation.NavHostController
import android.content.pm.PackageInfo
import androidx.compose.material3.ButtonDefaults
import kafva.kage.data.AppRepository
import kafva.kage.data.GitException
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.clickable
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.runtime.MutableState
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.flow.MutableStateFlow
import kafva.kage.G

@Composable
fun SettingsView(
    navigateToHistory: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val focusManager = LocalFocusManager.current
    val openAlertDialog = remember { mutableStateOf(false) }
    val remoteAddress = remember { mutableStateOf("") }
    val remoteRepoPath = remember { mutableStateOf("") }
    val currentError: MutableState<String?> = remember { mutableStateOf(null) }
    val passwordCount = viewModel.gitRepository.count.collectAsState()

    Column(modifier = G.containerModifier,
           verticalArrangement = Arrangement.Center,
           horizontalAlignment = Alignment.CenterHorizontally
    ) {
        TextFieldView(
            text = remoteAddress,
            leadingIcon =  { Icon(Icons.Filled.Home, "Remote address") },
            label =  { Text("Remote address") },
            onDone = {
                val newSettings = Settings(remoteAddress.value, remoteRepoPath.value)
                viewModel.updateSettings(newSettings)
                focusManager.moveFocus(FocusDirection.Down)
            }
        )

        TextFieldView(
            text = remoteRepoPath,
            leadingIcon =  { Icon(Icons.Filled.Person, "Repository") },
            label =  { Text("Repository") },
            onDone = {
                val newSettings = Settings(remoteAddress.value, remoteRepoPath.value)
                viewModel.updateSettings(newSettings)
                focusManager.moveFocus(FocusDirection.Down)
            }
        )

        Card(modifier = G.containerModifier) {
            TextButton(
                onClick = {
                    openAlertDialog.value = true
                },
                modifier = Modifier.padding(top = 4.dp, start = 20.dp)
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Icon(Icons.Filled.Refresh, "Reset")
                    Text("Reset password repository")
                }
            }

            TextButton(
                onClick = navigateToHistory,
                modifier = Modifier.padding(top = 4.dp, start = 20.dp)
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Icon(Icons.Filled.DateRange, "History")
                    Text("History")
                }
            }

            Text("Storage: ${passwordCount.value} password(s)",
                 modifier = Modifier.padding(top = 8.dp, start = 35.dp),
                 fontSize = 12.sp,
                 maxLines = 1,
                 color = Color.Gray)

            Text("Version: ${viewModel.appRepository.versionName}",
                 modifier = Modifier.padding(start = 35.dp, bottom = 10.dp),
                 fontSize = 12.sp,
                 maxLines = 1,
                 color = Color.Gray)
        }

        if (currentError.value != null) {
            Text("Error: ${currentError.value}",
                 color = MaterialTheme.colorScheme.error,
                 fontSize = 14.sp,
                 modifier = Modifier.padding(start = 35.dp,
                                             top = 10.dp,
                                             end = 20.dp)
                                    .clickable(true) {
                     currentError.value = null
                 }
             )
        }

        AlertView(openAlertDialog, currentError)

        LaunchedEffect(Unit) {
            // Fill the text fields with the current configuration from the
            // datastore when the view appears.
            viewModel.settingsRepository.flow.collect { s ->
                remoteAddress.value = s.remoteAddress
                remoteRepoPath.value = s.remoteRepoPath
            }
            currentError.value = null
        }
    }
}

@Composable
private fun AlertView(
    openAlertDialog: MutableState<Boolean>,
    currentError: MutableState<String?>,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
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
                Text("This operation will delete the local checkout.")
            },
            onDismissRequest = {
                openAlertDialog.value = false
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.clone(currentError)
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
}

@Composable
private fun TextFieldView(
    text: MutableState<String>,
    label: @Composable () -> Unit,
    leadingIcon: @Composable () -> Unit,
    onDone: (KeyboardActionScope.() -> Unit)?
) {
    TextField(
        value = text.value,
        leadingIcon = leadingIcon,
        label = label,
        onValueChange = {
            text.value = it
        },
        singleLine = true,
        shape = RoundedCornerShape(8.dp),
        modifier = Modifier.padding(bottom = 10.dp),
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done, keyboardType = KeyboardType.Text),
        keyboardActions = KeyboardActions(onDone = onDone),
        // Remove underline from textbox
        colors = TextFieldDefaults.colors(
            unfocusedIndicatorColor = Color.Transparent,
            disabledIndicatorColor = Color.Transparent
        )
    )
}
