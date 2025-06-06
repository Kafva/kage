package one.kafva.kage.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import dagger.hilt.android.lifecycle.HiltViewModel
import one.kafva.kage.G
import one.kafva.kage.R
import one.kafva.kage.data.AgeRepository
import one.kafva.kage.data.GitRepository
import one.kafva.kage.data.RuntimeSettingsRepository
import one.kafva.kage.types.Screen
import javax.inject.Inject

@HiltViewModel
class ToolbarViewModel
    @Inject
    constructor(
        val gitRepository: GitRepository,
        val ageRepository: AgeRepository,
        val runtimeSettingsRepository: RuntimeSettingsRepository,
    ) : ViewModel()

@Composable
fun ToolbarView(
    currentRoute: String,
    navigateToSettings: () -> Unit,
    content: @Composable (PaddingValues) -> Unit,
) {
    Scaffold(
        topBar = {
            when (currentRoute) {
                Screen.Home.route -> {
                    ToolbarRowView(
                        arrangement = Arrangement.Center,
                        bottomPadding = 5.dp,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        SearchView()
                    }
                }
                else -> {}
            }
        },
        bottomBar = {
            when (currentRoute) {
                Screen.Home.route -> {
                    ToolbarRowView(
                        arrangement = Arrangement.SpaceBetween,
                        topPadding = 5.dp,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        BottomBarView(navigateToSettings)
                    }
                }
                else -> {}
            }
        },
    ) { innerPadding ->
        content(innerPadding)
    }
}

@Composable
private fun ToolbarRowView(
    arrangement: Arrangement.Horizontal,
    topPadding: Dp = 30.dp,
    bottomPadding: Dp = 30.dp,
    modifier: Modifier? = null,
    content: @Composable () -> Unit,
) {
    Row(
        modifier =
            (modifier ?: Modifier)
                .padding(
                    top = topPadding,
                    bottom = bottomPadding,
                ),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = arrangement,
    ) {
        content()
    }
}

@Composable
private fun BottomBarView(
    navigateToSettings: () -> Unit,
    viewModel: ToolbarViewModel = hiltViewModel(),
) {
    val expandRecursively by viewModel.runtimeSettingsRepository
        .expandRecursively
        .collectAsStateWithLifecycle()

    val identityUnlockedAt by viewModel.ageRepository.identityUnlockedAt
        .collectAsStateWithLifecycle()
    IconButton(
        onClick = navigateToSettings,
        modifier = Modifier.padding(start = 10.dp),
    ) {
        Icon(
            Icons.Filled.Settings,
            "Settings",
            modifier = Modifier.size(G.MEDIUM_ICON_SIZE.dp),
        )
    }

    Row {
        IconButton(
            onClick = {
                viewModel.runtimeSettingsRepository.toggleExpandRecursively()
            },
            modifier = Modifier.padding(end = 10.dp),
        ) {
            val icon =
                if (expandRecursively) {
                    painterResource(R.drawable.collapse_all)
                } else {
                    painterResource(R.drawable.expand_all)
                }
            Image(
                icon,
                "Toggle tree expansion",
                colorFilter =
                    ColorFilter.tint(
                        MaterialTheme.colorScheme.onBackground,
                    ),
                modifier = Modifier.size(G.MEDIUM_ICON_SIZE.dp),
            )
        }

        IconButton(
            onClick = {
                viewModel.ageRepository.lockIdentity()
            },
            modifier = Modifier.padding(end = 10.dp),
            enabled = identityUnlockedAt != null,
        ) {
            val icon: Painter
            val colorFilter: ColorFilter
            if (identityUnlockedAt != null) {
                icon = painterResource(R.drawable.lock_open_right)
                colorFilter =
                    ColorFilter.tint(MaterialTheme.colorScheme.primary)
            } else {
                icon = painterResource(R.drawable.lock)
                colorFilter =
                    ColorFilter.tint(MaterialTheme.colorScheme.onBackground)
            }
            Image(
                icon,
                colorFilter = colorFilter,
                contentDescription = "Toggle lock",
                modifier = Modifier.size(G.MEDIUM_ICON_SIZE.dp),
            )
        }
    }
}

@Composable
private fun SearchView(viewModel: ToolbarViewModel = hiltViewModel()) {
    val query = viewModel.gitRepository.query.collectAsState()

    TextField(
        value = query.value,
        onValueChange = {
            if (it.isEmpty()) {
                // Disable autoexpansion when there is no query
                viewModel.runtimeSettingsRepository.setExpandRecursively(false)
            } else {
                // Autoexpand when there is a query string
                viewModel.runtimeSettingsRepository.setExpandRecursively(true)
            }
            viewModel.gitRepository.updateMatches(it)
        },
        placeholder = {
            Text(
                stringResource(R.string.search_placeholder),
                modifier = Modifier.fillMaxWidth(0.65f),
                textAlign = TextAlign.Start,
                fontSize = G.TITLE2_FONT_SIZE.sp,
                color = MaterialTheme.colorScheme.outline,
            )
        },
        singleLine = true,
        shape = RoundedCornerShape(8.dp),
        keyboardOptions =
            KeyboardOptions(
                imeAction = ImeAction.Done,
                keyboardType = KeyboardType.Text,
                capitalization = KeyboardCapitalization.None,
                autoCorrectEnabled = false,
            ),
        // Remove underline from textbox
        colors =
            TextFieldDefaults.colors(
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
                disabledIndicatorColor = Color.Transparent,
            ),
        textStyle =
            TextStyle(
                textAlign = TextAlign.Start,
                fontSize = G.TITLE2_FONT_SIZE.sp,
            ),
        modifier = Modifier.fillMaxWidth(0.6f),
    )
}
