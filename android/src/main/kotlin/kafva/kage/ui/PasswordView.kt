package kafva.kage.ui

import android.content.ClipData
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ClipEntry
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import dagger.hilt.android.lifecycle.HiltViewModel
import kafva.kage.G
import kafva.kage.Log
import kafva.kage.R
import kafva.kage.data.AgeException
import kafva.kage.data.AgeRepository
import kafva.kage.types.PwNode
import javax.inject.Inject

@HiltViewModel
class PasswordViewModel
    @Inject
    constructor(
        val ageRepository: AgeRepository,
    ) : ViewModel()

@Composable
fun PasswordView(
    serialisedNodePath: String,
    viewModel: PasswordViewModel = hiltViewModel(),
) {
    val context = LocalContext.current
    val clipboardManager = LocalClipboardManager.current
    val plaintext = viewModel.ageRepository.plaintext.collectAsState()
    val passphrase = viewModel.ageRepository.passphrase.collectAsState()
    val identityUnlockedAt by viewModel.ageRepository.identityUnlockedAt
        .collectAsStateWithLifecycle()
    val hidePlaintext: MutableState<Boolean> = remember { mutableStateOf(true) }
    val nodePath = PwNode.fromRoutePath(serialisedNodePath)
    val currentError: MutableState<String?> = remember { mutableStateOf(null) }

    Column(
        modifier = G.containerModifier,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (identityUnlockedAt != null) {
            Text(
                PwNode.prettyName(nodePath),
                fontSize = 20.sp,
                modifier = Modifier.padding(bottom = 20.dp),
            )
            Text(
                if (hidePlaintext.value) {
                    stringResource(R.string.password_placeholder)
                } else {
                    plaintext.value ?: ""
                },
                fontSize = 18.sp,
                color = MaterialTheme.colorScheme.primary,
                modifier =
                    Modifier
                        .padding(bottom = 15.dp)
                        .clickable(true) {
                            hidePlaintext.value =
                                !hidePlaintext.value
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
                        val clipEntry = ClipEntry(clipData)
                        clipboardManager.setClip(clipEntry)
                    }
                },
            ) {
                Text(stringResource(R.string.copy))
            }
        } else {
            Text(
                stringResource(R.string.authentication),
                fontSize = 20.sp,
                modifier = Modifier.padding(bottom = 12.dp),
            )
            TextField(
                value = passphrase.value ?: "",
                label = { Text(stringResource(R.string.passphrase)) },
                singleLine = true,
                shape = RoundedCornerShape(8.dp),
                onValueChange = {
                    viewModel.ageRepository.setPassphrase(it)
                },
                visualTransformation = PasswordVisualTransformation(Char(0x2A)),
                keyboardOptions =
                    KeyboardOptions(
                        imeAction = ImeAction.Done,
                        keyboardType = KeyboardType.Text,
                    ),
                keyboardActions =
                    KeyboardActions(
                        onDone = {
                            try {
                                viewModel.ageRepository.unlockIdentity(
                                    passphrase.value ?: "",
                                )
                                // Clear passphrase after trying it
                                viewModel.ageRepository.setPassphrase(null)
                                viewModel.ageRepository.decrypt(nodePath)
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

        if (currentError.value != null) {
            Text(
                context.getString(R.string.error, currentError.value),
                color = MaterialTheme.colorScheme.error,
                fontSize = 14.sp,
                modifier =
                    Modifier.padding(top = 10.dp).clickable(true) {
                        currentError.value = null
                    },
            )
        }

        LaunchedEffect(Unit) {
            try {
                // Automatically decrypt when the view appears if the identity is
                // already unlocked
                viewModel.ageRepository.decrypt(nodePath)
            } catch (e: AgeException) {
                Log.e(e.message ?: "Unknown error")
            }
            currentError.value = null
        }
    }
}
