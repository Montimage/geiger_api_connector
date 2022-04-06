package com.montimage.example

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import eu.cybergeiger.communication.GeigerService
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return GeigerService.claimEngine(context)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GeigerService.releaseEngine()
    }
}