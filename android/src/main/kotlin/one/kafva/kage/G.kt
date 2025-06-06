package one.kafva.kage

import android.os.Build
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

object G {
    const val LOCAL_REPO_NAME = "git-adc83b19e"

    const val AUTO_LOCK_SECONDS: Long = 120

    const val TITLE_FONT_SIZE = 26
    const val TITLE2_FONT_SIZE = 22
    const val BODY_FONT_SIZE = 18
    const val FOOTNOTE_FONT_SIZE = 14

    const val MEDIUM_ICON_SIZE = 30
    const val ICON_SIZE = 20

    const val CORNER_RADIUS = 8

    // Spacing modifier to apply on the main container element for each view
    val containerModifier = Modifier.fillMaxWidth(0.85f).padding(top = 20.dp)
    val containerModifierCentered =
        Modifier
            .fillMaxWidth(
                0.85f,
            ).padding(top = 60.dp)

    // Very basic check if we are on emulator
    val isEmulator =
        Build.MODEL.startsWith("sdk_gphone") ||
            Build.MODEL.startsWith("Android SDK")
}
