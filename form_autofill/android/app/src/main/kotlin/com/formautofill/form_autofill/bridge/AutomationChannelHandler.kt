package com.formautofill.form_autofill.bridge

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.formautofill.form_autofill.automation.AutomationController
import com.formautofill.form_autofill.overlay.AutomationOverlayService
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object AutomationChannelHandler {
    private const val METHOD_CHANNEL = "com.formautofill/automation"
    private const val EVENT_CHANNEL = "com.formautofill/automation/events"

    private var eventSink: EventChannel.EventSink? = null

    fun register(messenger: io.flutter.plugin.common.BinaryMessenger, context: Context) {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            handleMethod(call, result, context)
        }
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                AutomationController.statusListener = { map ->
                    events?.success(map)
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                AutomationController.statusListener = null
            }
        })
    }

    private fun handleMethod(call: MethodCall, result: MethodChannel.Result, context: Context) {
        when (call.method) {
            "isAccessibilityEnabled" -> {
                result.success(isAccessibilityServiceEnabled(context))
            }
            "isOverlayGranted" -> {
                result.success(canDrawOverlays(context))
            }
            "openAccessibilitySettings" -> {
                context.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
                result.success(null)
            }
            "openOverlaySettings" -> {
                val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${context.packageName}")
                    )
                } else {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:${context.packageName}"))
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                result.success(null)
            }
            "startAutomation" -> {
                @Suppress("UNCHECKED_CAST")
                val fields = call.argument<Map<String, String>>("fields") ?: emptyMap()
                val maxScroll = call.argument<Int>("maxScrollRetries") ?: 8
                val scrollDelay = call.argument<Int>("scrollDelayMs") ?: 600
                val retryDelay = call.argument<Int>("retryDelayMs") ?: 400
                val ocrThreshold = call.argument<Int>("ocrThreshold") ?: 65
                AutomationController.configure(
                    fields = fields,
                    maxScrollRetries = maxScroll,
                    scrollDelayMs = scrollDelay.toLong(),
                    retryDelayMs = retryDelay.toLong(),
                    ocrThreshold = ocrThreshold
                )
                AutomationController.requestStart()
                val overlayIntent = Intent(context, AutomationOverlayService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(overlayIntent)
                } else {
                    context.startService(overlayIntent)
                }
                result.success(null)
            }
            "stopAutomation" -> {
                AutomationController.requestStop()
                context.stopService(Intent(context, AutomationOverlayService::class.java))
                result.success(null)
            }
            "pauseAutomation" -> {
                AutomationController.requestPause()
                result.success(null)
            }
            "resumeAutomation" -> {
                AutomationController.requestResume()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.contains(context.packageName)
    }

    private fun canDrawOverlays(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else true
    }
}
