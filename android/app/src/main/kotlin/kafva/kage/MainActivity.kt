@file:Suppress("ktlint:standard:function-naming")

package kafva.kage

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import dagger.hilt.android.AndroidEntryPoint
import kafva.kage.ui.theme.KageTheme
import kafva.kage.ui.views.SettingsView
import kafva.kage.ui.views.TreeView

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            KageTheme {
                Column(
                    modifier = Modifier.fillMaxSize()
                                       .background(MaterialTheme.colorScheme.surface),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    SettingsView()
                    TreeView()
                }
            }
        }
    }

    init {
        System.loadLibrary("kage_core")
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