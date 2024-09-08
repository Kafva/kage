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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kafva.kage.ui.theme.KageTheme
import java.io.File

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val repoPath = "${this.filesDir.path}/${GIT_DIR_NAME}/james"

        setContent {
            KageTheme {
                Column(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    AppComposable(repoPath)
                }
            }
        }
    }

    init {
        System.loadLibrary("kage_core")
    }
}

@Composable
fun AppComposable(repoPath: String) {
    val git = Git()
    val errorState = remember { mutableStateOf("") }
    val logs = git.log(repoPath)

    Button(
        onClick = {
            // https://developer.android.com/studio/run/emulator-networking
            val url = "git://10.0.2.2:9418/james.git"

            File(repoPath).deleteRecursively()
            val r = git.clone(url, repoPath)
            errorState.value = if (r != 0) git.strerror() else ""
            Log.v("Cloned into $repoPath: $r")
        },
        modifier = Modifier.padding(top = 70.dp),
    ) {
        Text("clone")
    }
    Button(onClick = {
        val r = git.pull(repoPath)
        errorState.value = if (r != 0) git.strerror() else ""
        Log.v("Pulled $repoPath: $r")
    },
        modifier = Modifier.padding(bottom = 100.dp)
    ) {
        Text("pull")
    }
    if (errorState.value != "") {
        Text("Error: ${errorState.value}")
    }

    for (line in logs.split('\n')) {
        Text(line)
    }
}
