package kafva.kage.ui.views

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalFocusManager
import androidx.hilt.navigation.compose.hiltViewModel
import kafva.kage.data.Settings
import kafva.kage.data.SettingsViewModel
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
import androidx.compose.material.icons.Icons
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


@Composable
fun SettingsView(
    viewModel: SettingsViewModel = hiltViewModel()
) {
    //val focusManager = LocalFocusManager.current
    val remoteAddress = remember { mutableStateOf("") }

    Column {
        TextField(
            value = remoteAddress.value,
            onValueChange = {
                remoteAddress.value = it
            },
            placeholder = { Text("Server address") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done,
                                              keyboardType = KeyboardType.Ascii),
            keyboardActions = KeyboardActions(
                onDone = {
                    // https://developer.android.com/studio/run/emulator-networking
                    // git://10.0.2.2:9418/james.git
                    val newSettings = Settings("git://${remoteAddress.value}/james.git")
                    viewModel.updateSettings(newSettings)
                    //focusManager.clearFocus()
                }
            ),
        )

        Button(
            onClick = {
                viewModel.clone()
            },
        ) {
            Text("Clone")
        }
    }
}

