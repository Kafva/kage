package kafva.kage

import android.os.Bundle
import android.content.ContextWrapper
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.Button
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.unit.dp
import kafva.kage.ui.theme.KageTheme
import java.io.File;
import kafva.kage.Log
import kafva.kage.GIT_DIR_NAME

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val repoPath = "${this.filesDir.path}/${GIT_DIR_NAME}/james"

        setContent {
            KageTheme {
                Column(modifier = Modifier.fillMaxSize(),
                       verticalArrangement = Arrangement.spacedBy(10.dp),
                       horizontalAlignment = Alignment.CenterHorizontally) {
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
fun AppComposable(
    repoPath: String
) {
    val git = Git()
    val errorState = remember { mutableStateOf("") } 

    Button(onClick = {
            // https://developer.android.com/studio/run/emulator-networking
            val url = "git://10.0.2.2:9418/james.git"

            File(repoPath).deleteRecursively()
            val r = git.clone(url, repoPath)
            Log.v("Cloned into ${repoPath}: $r")
            if (r != 0) {
                errorState.value = git.strerror()
            }
        },
        modifier = Modifier.padding(top = 70.dp)
    ) {
        Text("clone")
    }
    Button(onClick = {
            val r = git.pull(repoPath)
            Log.v("Pulled ${repoPath}: $r")
            if (r != 0) {
                errorState.value = git.strerror()
            }
        }) {
        Text("pull")
    }
    if (errorState.value != "") {
        Text("Error: ${errorState.value}")
    }
}
