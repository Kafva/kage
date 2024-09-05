package kafva.kage

import android.util.Log as AndroidLog

const val TAG = "kafva.kage"

class Log {
    companion object {
        fun d(msg: String) {
            AndroidLog.d(TAG, "${this.getPrefix()}: ${msg}")
        }

        fun v(msg: String) {
            AndroidLog.v(TAG, "${this.getPrefix()}: ${msg}")
        }

        fun i(msg: String) {
            AndroidLog.i(TAG, "${this.getPrefix()}: ${msg}")
        }

        fun w(msg: String) {
            AndroidLog.w(TAG, "${this.getPrefix()}: ${msg}")
        }

        fun e(msg: String) {
            AndroidLog.e(TAG, "${this.getPrefix()}: ${msg}")
        }

        private fun getPrefix(): String {
            // getPrefix -> (d,v,i,w,e) -> calling method
            val stackTrace = Throwable().stackTrace[2]
            return "${stackTrace.fileName}:${stackTrace.lineNumber}"
        }
    }
}
