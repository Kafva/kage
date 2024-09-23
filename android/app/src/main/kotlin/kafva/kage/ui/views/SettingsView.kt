package kafva.kage.ui.views

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import kafva.kage.data.Settings
import kafva.kage.data.SettingsViewModel
import androidx.navigation.NavHostController
import kafva.kage.Git


@Composable
fun SettingsView(
    navController: NavHostController,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val currentSettings by viewModel.currentSettings.collectAsState(Settings(""))

    Button(
        onClick = {
            val newSettings = Settings("git://10.0.2.2:9418/james.git")
            viewModel.updateSettings(newSettings)
        },
        modifier = Modifier.padding(top = 70.dp),
    ) {
        Text("Update remote to james")
    }

    Button(
        onClick = {
            val newSettings = Settings("git://10.0.2.2:9418/jane.git")
            viewModel.updateSettings(newSettings)
        },
        modifier = Modifier.padding(top = 10.dp),
    ) {
        Text("Update remote to jane")
    }

    // Button(
    //     onClick = {
    //         // https://developer.android.com/studio/run/emulator-networking

    //         File(repoPath).deleteRecursively()
    //         val r = Git.clone(url, repoPath)
    //         errorState.value =
    //             if (r != 0) Git.strerror() ?: "Unknown error" else ""
    //         Log.v("Cloned into $repoPath: $r")
    //     },
    //     modifier = Modifier.padding(top = 70.dp),
    // ) {
    //     Text("clone")
    // }

    Text("Current remote: ${currentSettings.remoteAddress}")

}

