package one.kafva.kage.ui

import android.content.ClipData
import android.content.ClipDescription
import android.os.PersistableBundle
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ClipEntry
import androidx.compose.ui.platform.LocalClipboard
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import one.kafva.kage.BODY_FONT_SIZE
import one.kafva.kage.CONTAINER_MODIFIER_CENTERED
import one.kafva.kage.CORNER_RADIUS
import one.kafva.kage.Log
import one.kafva.kage.R
import one.kafva.kage.TITLE2_FONT_SIZE
import one.kafva.kage.TITLE_FONT_SIZE
import one.kafva.kage.data.AgeDataSource
import one.kafva.kage.data.AgeException
import one.kafva.kage.types.PwNode
import javax.inject.Inject

@HiltViewModel
class PasswordViewModel
    @Inject
    constructor(
        val ageDataSource: AgeDataSource,
    ) : ViewModel()

@Composable
fun PasswordView(
    serialisedNodePath: String,
    viewModel: PasswordViewModel = hiltViewModel(),
) {
    val context = LocalContext.current
    val identityUnlockedAt by viewModel.ageDataSource.identityUnlockedAt
        .collectAsStateWithLifecycle()
    val nodePath = PwNode.fromRoutePath(serialisedNodePath)
    val currentError: MutableState<String?> = remember { mutableStateOf(null) }

    Column(
        modifier = CONTAINER_MODIFIER_CENTERED,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (identityUnlockedAt != null) {
            PlaintextView(nodePath)
        } else {
            UnlockView(nodePath, currentError)
        }

        if (currentError.value != null) {
            val msg =
                if (currentError.value == "Decryption failed") {
                    stringResource(R.string.decryption_failed)
                } else {
                    currentError.value
                }
            Text(
                context.getString(R.string.error, msg),
                color = MaterialTheme.colorScheme.error,
                textAlign = TextAlign.Center,
                fontSize = BODY_FONT_SIZE.sp,
                modifier =
                    Modifier.padding(top = 10.dp, bottom = 10.dp)
                            .fillMaxWidth(0.65f)
                            .clip(RoundedCornerShape(CORNER_RADIUS))
                            .background(MaterialTheme.colorScheme.errorContainer)
                            .clickable(true) {
                        currentError.value = null
                    },
            )
        }

        LaunchedEffect(Unit) {
            try {
                // Automatically decrypt when the view appears if the identity is
                // already unlocked
                viewModel.ageDataSource.decrypt(nodePath)
            } catch (e: AgeException) {
                Log.e(e.message ?: "Unknown error")
            }
            currentError.value = null
        }
    }
}

@Composable
private fun PlaintextView(
    nodePath: String,
    viewModel: PasswordViewModel = hiltViewModel(),
) {
    val clipboard = LocalClipboard.current
    val coroutineScope = rememberCoroutineScope()
    val interactionSource = remember { MutableInteractionSource() }
    val hidePlaintext: MutableState<Boolean> = remember { mutableStateOf(true) }
    val plaintext = viewModel.ageDataSource.plaintext.collectAsState()

    Text(
        PwNode.prettyName(nodePath),
        fontSize = TITLE_FONT_SIZE.sp,
        fontWeight = FontWeight.Bold,
        modifier = Modifier.padding(bottom = 30.dp),
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
    )

    Text(
        if (hidePlaintext.value) {
            stringResource(R.string.password_placeholder)
        } else {
            plaintext.value ?: ""
        },
        fontSize =
            if (hidePlaintext.value) {
                35.sp // Placeholder dots are small
            } else {
                TITLE2_FONT_SIZE.sp
            },
        color = MaterialTheme.colorScheme.primary,
        modifier =
            Modifier
                .padding(top = 15.dp, bottom = 15.dp)
                .height(60.dp)
                .clickable(
                    indication = null,
                    interactionSource = interactionSource,
                ) {
                    hidePlaintext.value = !hidePlaintext.value
                },
    )

    TextButton(
        onClick = {
            if (plaintext.value != null) {
                val clipData =
                    ClipData.newPlainText(
                        "plaintext",
                        plaintext.value ?: "",
                    )
                clipData.description.extras =
                    PersistableBundle().apply {
                        putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
                    }
                val clipEntry = ClipEntry(clipData)
                coroutineScope.launch {
                    clipboard.setClipEntry(clipEntry)
                }
            }
        },
    ) {
        Text(stringResource(R.string.copy), fontSize = BODY_FONT_SIZE.sp)
    }
}

@Composable
private fun UnlockView(
    nodePath: String,
    currentError: MutableState<String?>,
    viewModel: PasswordViewModel = hiltViewModel(),
) {
    val password = viewModel.ageDataSource.password.collectAsState()

    Text(
        stringResource(R.string.authentication),
        fontSize = TITLE_FONT_SIZE.sp,
        modifier = Modifier.padding(bottom = 30.dp),
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
    )
    TextField(
        value = password.value ?: "",
        label = { Text(stringResource(R.string.password)) },
        singleLine = true,
        shape = RoundedCornerShape(CORNER_RADIUS),
        onValueChange = {
            viewModel.ageDataSource.setPassword(it)
        },
        visualTransformation = PasswordVisualTransformation(Char(0x2A)),
        keyboardOptions =
            KeyboardOptions(
                imeAction = ImeAction.Done,
                keyboardType = KeyboardType.Text,
                capitalization = KeyboardCapitalization.None,
                autoCorrectEnabled = false,
            ),
        keyboardActions =
            KeyboardActions(
                onDone = {
                    try {
                        viewModel.ageDataSource.unlockIdentity(
                            password.value ?: "",
                        )
                        // Clear password after trying it
                        viewModel.ageDataSource.setPassword(null)
                        viewModel.ageDataSource.decrypt(nodePath)
                        currentError.value = null
                    } catch (e: AgeException) {
                        currentError.value = e.message
                        Log.e(e.message ?: "Unknown error")
                    }
                },
            ),
        // Remove underline from textbox
        colors =
            TextFieldDefaults.colors(
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
                disabledIndicatorColor = Color.Transparent,
            ),
    )
}
