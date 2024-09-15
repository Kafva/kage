@file:Suppress("ktlint:standard:function-naming")

package kafva.kage

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import dagger.hilt.android.AndroidEntryPoint
import kafva.kage.data.PwNodeViewModel
import kafva.kage.data.SettingsViewModel
import kafva.kage.data.Settings
import kafva.kage.ui.theme.KageTheme
import java.io.File

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            KageTheme {
                Column(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    // AppComposable(repoPath)
                    SettingsView()
                    PwNodeTree()
                }
            }
        }
    }

    init {
        System.loadLibrary("kage_core")
    }
}

@Composable
fun SettingsView(viewModel: SettingsViewModel = hiltViewModel()) {
     //val currentSettings = viewModel.currentSettings

     Button(
         onClick = {
             val newSettings = Settings("git://10.0.2.2:9418/james.git")
             viewModel.updateSettings(newSettings)
         },
         modifier = Modifier.padding(top = 70.dp),
     ) {
         Text("Update remote")
     }

     //Text("Current remote: ${currentSettings.remoteAddress}")
}


@Composable
fun PwNodeTree(viewModel: PwNodeViewModel = hiltViewModel()) {
    val pwNodes by viewModel.pwNodes.collectAsState()

    pwNodes?.let { node ->
        Text(node.name)
    }
}

// @Composable
// fun AppComposable(repoPath: String) {
//     val age = Age()
//     val git = Git()
//     val errorState = remember { mutableStateOf("") }
//     val unlockState = remember { mutableStateOf(false) }
//     val plaintextState = remember { mutableStateOf("") }
//     val logs = git.log(repoPath)

//     Button(
//         onClick = {
//             // https://developer.android.com/studio/run/emulator-networking
//             val url = "git://10.0.2.2:9418/james.git"

//             File(repoPath).deleteRecursively()
//             val r = git.clone(url, repoPath)
//             errorState.value =
//                 if (r != 0) git.strerror() ?: "Unknown error" else ""
//             Log.v("Cloned into $repoPath: $r")
//         },
//         modifier = Modifier.padding(top = 70.dp),
//     ) {
//         Text("clone")
//     }
//     Button(
//         onClick = {
//             val r = git.pull(repoPath)
//             errorState.value =
//                 if (r != 0) git.strerror() ?: "Unknown error" else ""
//             Log.v("Pulled $repoPath: $r")
//         },
//         modifier = Modifier.padding(bottom = 100.dp),
//     ) {
//         Text("pull")
//     }
//     if (errorState.value != "") {
//         Text("Error: ${errorState.value}")
//     }

//     for (line in logs) {
//         Text(line)
//     }

//     Button(
//         onClick = {
//             var r: Int
//             if (unlockState.value) {
//                 r = age.lockIdentity()
//                 Log.v("Identity locked: $r")
//                 if (r == 0) {
//                     unlockState.value = false
//                 }
//             } else {
//                 val encryptedIdentity =
//                     File(
//                         "$repoPath/.age-identities",
//                     ).readText()
//                 val passphrase = "x"
//                 r = age.unlockIdentity(encryptedIdentity, passphrase)
//                 Log.v("Identity unlocked: $r")
//                 if (r == 0) {
//                     unlockState.value = true
//                 }
//             }

//             errorState.value =
//                 if (r != 0) age.strerror() ?: "Unknown error" else ""
//         },
//         modifier = Modifier.padding(bottom = 100.dp),
//     ) {
//         Text(if (unlockState.value) "Lock" else "Unlock")
//     }

//     Button(
//         onClick = {
//             val encryptedPath = "$repoPath/red/pass1.age"
//             plaintextState.value = age.decrypt(encryptedPath) ?: ""
//         },
//         modifier = Modifier.padding(bottom = 100.dp),
//     ) {
//         Text(
//             if (plaintextState.value !=
//                 ""
//             ) {
//                 "Decrypted: ${plaintextState.value}"
//             } else {
//                 "Decrypt"
//             },
//         )
//     }
// }
