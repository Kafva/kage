package kafva.kage.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActionScope
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kafva.kage.G
import kafva.kage.Log
import kafva.kage.R
import kafva.kage.data.AppRepository
import kafva.kage.data.GitException
import kafva.kage.data.GitRepository
import kafva.kage.data.SettingsRepository
import kafva.kage.types.Settings
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    val gitRepository: GitRepository,
    val settingsRepository: SettingsRepository,
    val appRepository: AppRepository,
) : ViewModel()

@Composable
fun SettingsView(
    navigateToHistory: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val focusManager = LocalFocusManager.current
    val openAlertDialog = remember { mutableStateOf(false) }
    val remoteAddress = remember { mutableStateOf("") }
    val remoteRepoPath = remember { mutableStateOf("") }
    val currentError: MutableState<String?> = remember { mutableStateOf(null) }
    val passwordCount = viewModel.gitRepository.passwordCount.collectAsState()

    val onDone: (KeyboardActionScope) -> Unit = {
        coroutineScope.launch {
            val newSettings = Settings(remoteAddress.value, remoteRepoPath.value)
            viewModel.settingsRepository.updateSettings(newSettings)
            focusManager.moveFocus(FocusDirection.Down)
        }
    }

    Column(modifier = G.containerModifier,
           verticalArrangement = Arrangement.Center,
           horizontalAlignment = Alignment.CenterHorizontally
    ) {
        TextFieldView(
            text = remoteAddress,
            leadingIcon =  { Icon(Icons.Filled.Home, stringResource(R.string.remote_address)) },
            label =  { Text(stringResource(R.string.remote_address)) },
            onDone = onDone
        )

        TextFieldView(
            text = remoteRepoPath,
            leadingIcon =  { Icon(Icons.Filled.Person, stringResource(R.string.repository)) },
            label =  { Text(stringResource(R.string.repository)) },
            onDone = onDone
        )

        Card(modifier = G.containerModifier) {
            TextButton(
                onClick = {
                    openAlertDialog.value = true
                },
                modifier = Modifier.padding(top = 4.dp, start = 20.dp)
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Icon(Icons.Filled.Refresh, stringResource(R.string.reset_repository))
                    Text(stringResource(R.string.reset_repository))
                }
            }

            TextButton(
                onClick = navigateToHistory,
                modifier = Modifier.padding(top = 4.dp, start = 20.dp)
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Image(
                        painterResource(R.drawable.family_history),
                        stringResource(R.string.history),
                        colorFilter = ColorFilter.tint(MaterialTheme.colorScheme.primary))
                    Text(stringResource(R.string.history))
                }
            }

            Text(context.getString(R.string.password_count, passwordCount.value),
                 modifier = Modifier.padding(top = 8.dp, start = 35.dp),
                 fontSize = 12.sp,
                 maxLines = 1,
                 color = Color.Gray)

            Text(context.getString(R.string.version, viewModel.appRepository.versionName),
                 modifier = Modifier.padding(start = 35.dp, bottom = 10.dp),
                 fontSize = 12.sp,
                 maxLines = 1,
                 color = Color.Gray)
        }

        if (currentError.value != null) {
            Text(context.getString(R.string.error, currentError.value),
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
    val coroutineScope = rememberCoroutineScope()

    val cloneOnClick: () -> Unit = {
        coroutineScope.launch {
            viewModel.settingsRepository.flow.collect { s ->
                try {
                    viewModel.gitRepository.clone(s.remoteAddress, s.remoteRepoPath)
                    currentError.value = null
                }
                catch (e: GitException) {
                    currentError.value = e.message
                    Log.e(e.message ?: "Unknown error")
                }
                openAlertDialog.value = false
            }
        }
    }

    if (openAlertDialog.value) {
        AlertDialog(
            icon = {
                Icon(Icons.Filled.Warning, "Warning")
            },
            title = {
                Text(stringResource(R.string.alert_title))
            },
            text = {
                Text(stringResource(R.string.alert_text))
            },
            onDismissRequest = {
                openAlertDialog.value = false
            },
            confirmButton = {
                TextButton(onClick = cloneOnClick) {
                    Text(stringResource(R.string.yes), color = Color.Red)
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        openAlertDialog.value = false
                    }
                ) {
                    Text(stringResource(R.string.no))
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
