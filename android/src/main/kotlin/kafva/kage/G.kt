package kafva.kage

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import android.os.Build;

object G {
    const val LOCAL_REPO_NAME = "git-adc83b19e"

    // Spacing modifier to apply on the main container element for each view
    val containerModifier = Modifier.fillMaxWidth(0.85f).padding(top = 20.dp)

    // Very basic check if we are on emulator
    val isEmulator = Build.MODEL.startsWith("sdk_gphone")
}

