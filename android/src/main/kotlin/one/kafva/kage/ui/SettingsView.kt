package one.kafva.kage.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActionScope
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.painter.Painter
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
import kotlinx.coroutines.launch
import one.kafva.kage.G
import one.kafva.kage.Log
import one.kafva.kage.R
import one.kafva.kage.data.AppRepository
import one.kafva.kage.data.GitException
import one.kafva.kage.data.GitRepository
import one.kafva.kage.data.SettingsRepository
import one.kafva.kage.types.Settings
import javax.inject.Inject

const val LEADING_PADDING = 10

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
        modifier = G.containerModifierCentered,
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
                    modifier = Modifier.size(G.ICON_SIZE.dp),
                )
            },
            label = { Text(stringResource(R.string.repository)) },
            onDone = onDone,
        )

        Card(modifier = G.containerModifier) {
            Spacer(modifier = Modifier.height(20.dp))

            TextLinkView(
                stringResource(R.string.reset_repository),
                painterResource(R.drawable.settings_backup_restore),
            ) {
                openAlertDialog.value = true
            }

            TextLinkView(
                stringResource(R.string.history),
                painterResource(R.drawable.linked_services),
            ) {
                navigateToHistory()
            }

            TextFooterView(
                context.getString(R.string.password_count, passwordCount.value),
            )

            TextFooterView(
                context.getString(
                    if (viewModel.appRepository.isDebug) {
                        R.string.version_debug
                    } else {
                        R.string.version_release
                    },
                    stringResource(R.string.git_version),
                ),
            )

            Spacer(modifier = Modifier.height(10.dp))
        }

        if (currentError.value != null) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Start,
                modifier =
                    Modifier
                        .fillMaxWidth(0.85f)
                        .padding(top = 12.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .clickable(true) {
                            currentError.value = null
                        },
            ) {
                Text(
                    context.getString(R.string.error, currentError.value),
                    color = MaterialTheme.colorScheme.error,
                    fontSize = G.BODY_FONT_SIZE.sp,
                    modifier = Modifier.padding(start = 4.dp),
                )
            }
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
                    Text(
                        stringResource(R.string.no),
                        color = MaterialTheme.colorScheme.onBackground,
                    )
                }
            },
            modifier = Modifier.fillMaxWidth(0.95f),
        )
    }
}

@Composable
private fun TextFooterView(text: String) {
    Text(
        text,
        modifier =
            Modifier.padding(
                start = (LEADING_PADDING + 12).dp,
                bottom = 10.dp,
            ),
        fontSize = G.FOOTNOTE_FONT_SIZE.sp,
        maxLines = 1,
        color = MaterialTheme.colorScheme.outline,
    )
}

@Composable
private fun TextLinkView(
    text: String,
    painter: Painter,
    action: (() -> Unit),
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Start,
        // Expand the area of the ripple click effect
        modifier =
            Modifier
                .height(50.dp)
                .fillMaxWidth(0.85f)
                .padding(start = LEADING_PADDING.dp, bottom = 8.dp)
                .clip(RoundedCornerShape(8.dp))
                .clickable(true) { action() },
    ) {
        Row(modifier = Modifier.padding(start = 12.dp)) {
            Image(
                painter,
                "Link",
                colorFilter =
                    ColorFilter.tint(
                        MaterialTheme.colorScheme.onBackground,
                    ),
                modifier =
                    Modifier
                        .size(
                            G.ICON_SIZE.dp,
                        ),
            )
        }

        Text(
            text,
            fontSize = G.BODY_FONT_SIZE.sp,
            color = MaterialTheme.colorScheme.onSurface,
            maxLines = 1,
            modifier = Modifier.padding(start = 12.dp, end = 12.dp),
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
        shape = RoundedCornerShape(G.CORNER_RADIUS),
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
