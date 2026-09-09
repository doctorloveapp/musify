package com.danilo.musify

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {
  private var localAudioMediaStoreChannel: LocalAudioMediaStoreChannel? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    localAudioMediaStoreChannel?.dispose()
    localAudioMediaStoreChannel = LocalAudioMediaStoreChannel(
      this,
      flutterEngine.dartExecutor.binaryMessenger,
    )
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    // Aligns the Flutter view vertically with the window.
    WindowCompat.setDecorFitsSystemWindows(getWindow(), false)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      // Disable the Android splash screen fade out animation to avoid
      // a flicker before the similar frame is drawn in Flutter.
      splashScreen.setOnExitAnimationListener { splashScreenView -> splashScreenView.remove() }
    }

    super.onCreate(savedInstanceState)
  }

  override fun onDestroy() {
    localAudioMediaStoreChannel?.dispose()
    localAudioMediaStoreChannel = null
    super.onDestroy()
  }
}
