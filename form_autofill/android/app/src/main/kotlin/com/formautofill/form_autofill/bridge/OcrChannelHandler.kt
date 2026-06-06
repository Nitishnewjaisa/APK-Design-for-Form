package com.formautofill.form_autofill.bridge

import android.graphics.BitmapFactory
import com.formautofill.form_autofill.engine.LabelMatcherEngine
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Shared OCR bridge for Flutter hybrid layer (Android ML Kit).
 */
object OcrChannelHandler {
    private const val CHANNEL = "com.formautofill/ocr"

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "extractLabels" -> {
                    val path = call.argument<String>("imagePath")
                    val minConf = call.argument<Int>("minConfidence") ?: 65
                    if (path == null) {
                        result.error("INVALID", "imagePath required", null)
                        return@setMethodCallHandler
                    }
                    extractFromPath(path, minConf, result)
                }
                "extractLabelsFromBytes" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val minConf = call.argument<Int>("minConfidence") ?: 65
                    if (bytes == null) {
                        result.error("INVALID", "bytes required", null)
                        return@setMethodCallHandler
                    }
                    val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                    if (bmp == null) {
                        result.success(emptyList<Map<String, Any>>())
                        return@setMethodCallHandler
                    }
                    extractFromBitmap(bmp, minConf, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun extractFromPath(
        path: String,
        minConf: Int,
        result: MethodChannel.Result
    ) {
        val bmp = BitmapFactory.decodeFile(path)
        if (bmp == null) {
            result.success(emptyList<Map<String, Any>>())
            return
        }
        extractFromBitmap(bmp, minConf, result)
    }

    private fun extractFromBitmap(
        bitmap: android.graphics.Bitmap,
        minConf: Int,
        result: MethodChannel.Result
    ) {
        val image = InputImage.fromBitmap(bitmap, 0)
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        recognizer.process(image)
            .addOnSuccessListener { visionText ->
                val labels = mutableListOf<Map<String, Any>>()
                for (block in visionText.textBlocks) {
                    for (line in block.lines) {
                        val text = line.text.trim()
                        if (text.length < 2) continue
                        val box = line.boundingBox ?: continue
                        val key = LabelMatcherEngine.matchLabel(text, minConf)
                        labels.add(
                            mapOf(
                                "text" to text,
                                "x" to box.left.toDouble(),
                                "y" to box.top.toDouble(),
                                "width" to box.width().toDouble(),
                                "height" to box.height().toDouble(),
                                "confidence" to 80,
                                "matchedFieldKey" to (key ?: "")
                            )
                        )
                    }
                }
                result.success(labels)
                bitmap.recycle()
            }
            .addOnFailureListener { e ->
                result.error("OCR_FAIL", e.message, null)
            }
    }
}
