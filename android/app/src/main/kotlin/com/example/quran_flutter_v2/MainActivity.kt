package com.example.quran_flutter_v2

import android.content.Context
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    // audio_service (used by just_audio_background) runs playback in a
    // background-capable FlutterEngine it owns; MainActivity must hand that
    // engine back instead of creating its own, or the foreground service /
    // media-button handling never binds correctly.
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return AudioServicePlugin.getFlutterEngine(context)
    }
}
