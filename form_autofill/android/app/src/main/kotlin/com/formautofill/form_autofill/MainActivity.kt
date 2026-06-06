package com.formautofill.form_autofill

import com.formautofill.form_autofill.bridge.AutomationChannelHandler
import com.formautofill.form_autofill.bridge.OcrChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        AutomationChannelHandler.register(messenger, this)
        OcrChannelHandler.register(messenger)
    }
}
