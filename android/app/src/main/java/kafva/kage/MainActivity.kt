package kafva.kage

import android.os.Bundle
import android.util.Log
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
                            val git = Git()
                            // TODO
                            //val appDir = ContextWrapper.getFilesDir().getAbsolutePath()
                            val r = git.clone("git://127.0.0.1/james.git", "/james")
                            Log.i("kafva.kage", "OK: $r")
                        }) {
                        Text("Bury me")
                    }
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        Log.v("kafva.kage", "Starting...")
        val git = Git()
        val r = git.clone("git://127.0.0.1/james.git", "james")
        Log.v("kafva.kage", "${Thread.currentThread().stackTrace[2].methodName}: $r")
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
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "Hello $name!",
        modifier = modifier
    )
}


/**
 * A group of *members*.
 *
 * This class has no useful logic; it's just a documentation example.
 *
 * @param T the type of a member in this group.
 * @property name the name of this group.
 * @constructor Creates an empty group.
 */
class Group<T>(val name: String) {
    /**
     * Adds a [member] to this group.
     * @return the new size of the group.
     */
    fun add(member: T): Int { return 1 }
}
