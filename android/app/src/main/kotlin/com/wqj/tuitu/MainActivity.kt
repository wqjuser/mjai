package com.wqj.tuitu

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Toast

class MainActivity: FlutterActivity() {
    private var doubleBackToExitPressedOnce = false
    private val handler = Handler(Looper.getMainLooper())
    private val exitRunnable = Runnable { doubleBackToExitPressedOnce = false }

    override fun onBackPressed() {
        if (doubleBackToExitPressedOnce) {
            super.onBackPressed()
            return
        }

        this.doubleBackToExitPressedOnce = true
        Toast.makeText(this, "再按一次退出应用", Toast.LENGTH_SHORT).show()

        handler.postDelayed(exitRunnable, 2000)
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(exitRunnable)
    }
}
