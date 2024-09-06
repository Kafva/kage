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

        setContent {
            KageTheme {
                Column(modifier = Modifier.fillMaxSize(),
                       verticalArrangement = Arrangement.spacedBy(10.dp),
                       horizontalAlignment = Alignment.CenterHorizontally) {
                    Greeting(
                        name = "Android",
                        modifier = Modifier.padding(0.dp, 20.dp)
                    )
                    Button(onClick = {
                        clone()
                        }) {
                        Text("clone")
                    }
                    Button(onClick = {
                        pull()
                        }) {
                        Text("pull")
                    }
                    if (errorState != "") {
                        Text("Error: $errorState")
                    }
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        Log.v("Starting...")
        clone()
    }

    var errorState by remember {
        mutableStateOf("")
    }

    private fun pull() {
        val repoPath = "${this.filesDir.path}/${GIT_DIR_NAME}/james"

        val git = Git()
        val r = git.pull(repoPath)
        Log.v("Pulled ${repoPath}: $r")
        if (r != 0) {
            errorState = git.strerror()
        }
    }

    private fun clone() {
        // https://developer.android.com/studio/run/emulator-networking
        val url = "git://10.0.2.2:9418/james.git"
        val into = "${this.filesDir.path}/${GIT_DIR_NAME}/james"

        File(into).deleteRecursively()
        val git = Git()
        val r = git.clone(url, into)
        Log.v("Cloned into ${into}: $r")
        if (r != 0) {
            errorState = git.strerror()
        }
    }

    init {
        System.loadLibrary("kage_core")
    }
}

/**
 * @param name the name
 * @param modifier the modifier
 */
@Composable
fun AppComposable(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "Hello $name!",
        modifier = modifier
    )
}
