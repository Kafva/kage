package kafva.kage.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActionScope
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
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
class SettingsViewModel
    @Inject
    constructor(
        val gitRepository: GitRepository,
        val settingsRepository: SettingsRepository,
        val appRepository: AppRepository,
    ) : ViewModel()

@Composable
fun SettingsView(
    navigateToHistory: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val openAlertDialog = remember { mutableStateOf(false) }
    val cloneUrl = remember { mutableStateOf("") }
    val currentError: MutableState<String?> = remember { mutableStateOf(null) }
    val passwordCount = viewModel.gitRepository.passwordCount.collectAsState()

    val onDone: (KeyboardActionScope) -> Unit = {
        coroutineScope.launch {
            val newSettings = Settings(cloneUrl.value)
            viewModel.settingsRepository.updateSettings(newSettings)
        }
    }

    Column(
        modifier = G.containerModifier,
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        TextFieldView(
            text = cloneUrl,
            leadingIcon = {
                Image(
                    painterResource(R.drawable.my_location),
                    stringResource(R.string.repository),
                    colorFilter =
                        ColorFilter.tint(
                            MaterialTheme.colorScheme.onBackground,
                        ),
                )
            },
            label = { Text(stringResource(R.string.repository)) },
            onDone = onDone,
        )

        Card(modifier = G.containerModifier) {
            Spacer(modifier = Modifier.height(20.dp))

            TextLinkView(stringResource(R.string.reset_repository)) {
                openAlertDialog.value =
                    true
            }

            TextLinkView(
                stringResource(R.string.history),
            ) { navigateToHistory() }

            TextFooterView(
                context.getString(R.string.password_count, passwordCount.value),
            )

            TextFooterView(
                context.getString(
                    R.string.version,
                    viewModel.appRepository.versionName,
                ),
            )

            Spacer(modifier = Modifier.height(10.dp))
        }

        if (currentError.value != null) {
            Text(
                context.getString(R.string.error, currentError.value),
                color = MaterialTheme.colorScheme.error,
                fontSize = 14.sp,
                modifier =
                    Modifier
                        .padding(
                            start = 35.dp,
                            top = 10.dp,
                            end = 20.dp,
                        ).clickable(true) {
                            currentError.value = null
                        },
            )
        }

        AlertView(openAlertDialog, currentError)

        LaunchedEffect(Unit) {
            // Fill the text fields with the current configuration from the
            // datastore when the view appears.
            viewModel.settingsRepository.flow.collect { s ->
                cloneUrl.value = s.cloneUrl
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
                    viewModel.gitRepository.clone(s.cloneUrl)
                    currentError.value = null
                } catch (e: GitException) {
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
                    },
                ) {
                    Text(stringResource(R.string.no))
                }
            },
        )
    }
}

@Composable
private fun TextFooterView(text: String) {
    Text(
        text,
        modifier = Modifier.padding(start = 35.dp, bottom = 10.dp),
        fontSize = 12.sp,
        maxLines = 1,
        color = MaterialTheme.colorScheme.outline,
    )
}

@Composable
private fun TextLinkView(
    text: String,
    action: (() -> Unit),
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
        modifier =
            Modifier
                .fillMaxWidth(
                    0.95f,
                ).padding(bottom = 20.dp, start = 35.dp)
                .clickable(true) { action() },
    ) {
        Text(
            text,
            fontSize = 14.sp,
            color = MaterialTheme.colorScheme.onSurface,
            maxLines = 1,
            modifier = Modifier.padding(end = 4.dp),
        )

        Icon(
            Icons.AutoMirrored.Filled.KeyboardArrowRight,
            text,
            tint = MaterialTheme.colorScheme.primary,
        )
    }
}

@Composable
private fun TextFieldView(
    text: MutableState<String>,
    label: @Composable () -> Unit,
    leadingIcon: @Composable () -> Unit,
    onDone: (KeyboardActionScope.() -> Unit)?,
    enabled: Boolean = true,
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
        modifier = Modifier.padding(bottom = 10.dp).fillMaxWidth(0.85f),
        keyboardOptions =
            KeyboardOptions(
                imeAction = ImeAction.Done,
                keyboardType = KeyboardType.Text,
                capitalization = KeyboardCapitalization.None,
                autoCorrectEnabled = false,
            ),
        keyboardActions = KeyboardActions(onDone = onDone),
        // Remove underline from textbox
        colors =
            TextFieldDefaults.colors(
                unfocusedIndicatorColor = Color.Transparent,
                disabledIndicatorColor = Color.Transparent,
            ),
        enabled = enabled,
    )
}
