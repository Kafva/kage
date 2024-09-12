package kafva.kage

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Application which sets up our dependency [Graph] with a context.
 */
@HiltAndroidApp
class KageApplication : Application()
