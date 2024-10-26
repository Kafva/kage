package kafva.kage

import android.app.Application
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import dagger.hilt.android.AndroidEntryPoint
import dagger.hilt.android.HiltAndroidApp
import kafva.kage.ui.AppView
import kafva.kage.ui.theme.KageTheme

@HiltAndroidApp
class KageApplication : Application()

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            KageTheme {
                AppView()
            }
        }
    }

    init {
        System.loadLibrary("kage_core")
    }
}
