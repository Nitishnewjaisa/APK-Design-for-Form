package com.formautofill.form_autofill.ocr

import android.graphics.Bitmap
import android.graphics.Rect
import android.util.Log
import com.formautofill.form_autofill.engine.LabelMatcherEngine
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * ML Kit OCR layer for label detection when accessibility labels are missing.
 */
class OcrService {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    private val tag = "OcrService"

    fun extractLabels(bitmap: Bitmap, minConfidence: Int = 65): List<Pair<String, Rect>> {
        val image = InputImage.fromBitmap(bitmap, 0)
        val latch = CountDownLatch(1)
        val resultRef = AtomicReference<List<Pair<String, Rect>>>(emptyList())

        recognizer.process(image)
            .addOnSuccessListener { visionText ->
                val labels = mutableListOf<Pair<String, Rect>>()
                for (block in visionText.textBlocks) {
                    for (line in block.lines) {
                        val text = line.text.trim()
                        if (text.length < 3 || text.length > 80) continue
                        val box = line.boundingBox ?: continue
                        val key = LabelMatcherEngine.matchLabel(text, minConfidence)
                        if (key != null) {
                            labels.add(text to Rect(box))
                        } else if (text.any { it.isLetter() }) {
                            labels.add(text to Rect(box))
                        }
                    }
                }
                resultRef.set(labels)
                latch.countDown()
            }
            .addOnFailureListener { e ->
                Log.e(tag, "OCR failed", e)
                latch.countDown()
            }

        latch.await(8, TimeUnit.SECONDS)
        return resultRef.get()
    }

    fun shutdown() {
        recognizer.close()
    }
}
