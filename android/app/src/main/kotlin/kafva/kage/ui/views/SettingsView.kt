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


@Composable
fun SettingsView(viewModel: SettingsViewModel = hiltViewModel()) {
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

     Text("Current remote: ${currentSettings.remoteAddress}")
}
