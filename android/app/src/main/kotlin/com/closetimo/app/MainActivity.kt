package com.closetimo.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    /** 005 — 기기 내 사진 분석 채널(배경 제거·라벨·Gemini Nano). */
    private var vision: ClosetimoVisionChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        vision = ClosetimoVisionChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        vision?.dispose()
        vision = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
