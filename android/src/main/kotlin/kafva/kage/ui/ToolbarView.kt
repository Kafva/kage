package kafva.kage.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.Scaffold
import androidx.compose.material3.IconButton
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.FloatingActionButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.material.icons.Icons
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material3.BottomAppBarDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SearchBar
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.ui.unit.dp
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.Alignment
import androidx.navigation.compose.rememberNavController
import androidx.navigation.compose.currentBackStackEntryAsState
import kafva.kage.types.Screen
import androidx.navigation.NavHostController
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kafva.kage.Log
import android.os.Build;
import androidx.compose.foundation.Image
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.IconButtonColors
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import kafva.kage.R
import javax.inject.Inject
import dagger.hilt.android.lifecycle.HiltViewModel
import androidx.lifecycle.ViewModel
import kafva.kage.data.RuntimeSettingsRepository
import kafva.kage.data.AppRepository
import kafva.kage.data.GitRepository
import kafva.kage.data.AgeRepository

@HiltViewModel
class ToolbarViewModel @Inject constructor(
    val appRepository: AppRepository,
    val gitRepository: GitRepository,
    val ageRepository: AgeRepository,
    val runtimeSettingsRepository: RuntimeSettingsRepository,
) : ViewModel() {}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ToolbarView(
    currentRoute: String,
    navigateToSettings: () -> Unit,
    navigateBack: () -> Unit,
    content: @Composable (PaddingValues) -> Unit
) {
    Scaffold(
        topBar = {
            when (currentRoute) {
                Screen.Home.route -> {
                    ToolbarRow(arrangement = Arrangement.Center) {
                        SearchField()
                    }
                }
                else -> {
                    ToolbarRow(arrangement = Arrangement.Start) {
                        IconButton(onClick = navigateBack) {
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, "Go home")
                        }

                        if (!currentRoute.contains("/")) {
                            Text(currentRoute)
                        }
                    }
                }
            }
        },
        bottomBar = {
            when (currentRoute) {
                Screen.Home.route -> {
                    ToolbarRow(arrangement = Arrangement.SpaceBetween) {
                        BottomBar(navigateToSettings)
                    }
                }
                else -> {}
            }

        }

    ) { innerPadding ->
        content(innerPadding)
    }
}

@Composable
private fun ToolbarRow(
    arrangement: Arrangement.Horizontal,
    viewModel: ToolbarViewModel = hiltViewModel(),
    content: @Composable () -> Unit
) {
    Row(modifier = Modifier.padding(top = 30.dp, bottom = 30.dp).fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = arrangement) {
        content()
    }
}

@Composable
private fun BottomBar(
    navigateToSettings: () -> Unit,
    viewModel: ToolbarViewModel = hiltViewModel(),
    ) {
    val expandRecursively by viewModel.runtimeSettingsRepository
        .expandRecursively.collectAsStateWithLifecycle()

    val identityUnlockedAt by viewModel.ageRepository.identityUnlockedAt
                                       .collectAsStateWithLifecycle()
    IconButton(onClick = navigateToSettings,
        modifier = Modifier.padding(start = 10.dp)
    ) {
        Icon(Icons.Filled.Settings, "Settings")
    }

    Row {
        IconButton(onClick = {
            viewModel.runtimeSettingsRepository.toggleExpandRecursively()
        },
            modifier = Modifier.padding(end = 10.dp)) {
            val icon = if (expandRecursively)
                            painterResource(R.drawable.collapse_all)
                       else painterResource(R.drawable.expand_all)
            Image(icon, "Toggle tree expansion")
        }

        IconButton(onClick = {
                viewModel.ageRepository.lockIdentity()
            },
            modifier = Modifier.padding(end = 10.dp),
            enabled = identityUnlockedAt != null
        ) {
            val icon: Painter
            val colorFilter: ColorFilter
            if (identityUnlockedAt != null) {
                icon = painterResource(R.drawable.lock_open_right)
                colorFilter = ColorFilter.tint(MaterialTheme.colorScheme.primary)
            }
            else {
                icon = painterResource(R.drawable.lock)
                colorFilter = ColorFilter.tint(MaterialTheme.colorScheme.surfaceDim)
            }
            Image(icon, colorFilter = colorFilter, contentDescription = "Toggle lock")
        }
    }
}

@Composable
private fun SearchField(viewModel: ToolbarViewModel = hiltViewModel()) {
    val query = viewModel.gitRepository.query.collectAsState()

    TextField(
        value = query.value,
        onValueChange = {
            viewModel.gitRepository.updateMatches(it)
        },
        placeholder = {
            Text(
                stringResource(R.string.search_placeholder),
                modifier = Modifier.fillMaxWidth(0.65f),
                textAlign = TextAlign.Center
            )
        },
        singleLine = true,
        shape = RoundedCornerShape(8.dp),
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done, keyboardType = KeyboardType.Text),
        // Remove underline from textbox
        colors = TextFieldDefaults.colors(
            focusedIndicatorColor = Color.Transparent,
            unfocusedIndicatorColor = Color.Transparent,
            disabledIndicatorColor = Color.Transparent
        ),
        textStyle = TextStyle(textAlign = TextAlign.Center)
    )
}