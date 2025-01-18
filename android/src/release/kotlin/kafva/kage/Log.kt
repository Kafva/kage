package kafva.kage

import android.util.Log as AndroidLog

const val TAG = "kafva.kage" // XXX

@Suppress("unused")
class Log {
    companion object {
        fun d(msg: String) {
            AndroidLog.d(TAG, msg)
        }

        fun v(msg: String) {
            AndroidLog.v(TAG, msg)
        }

        fun i(msg: String) {
            AndroidLog.i(TAG, msg)
        }

        fun w(msg: String) {
            AndroidLog.w(TAG, msg)
        }

        fun e(msg: String) {
            AndroidLog.e(TAG, msg)
        }
    }
}
