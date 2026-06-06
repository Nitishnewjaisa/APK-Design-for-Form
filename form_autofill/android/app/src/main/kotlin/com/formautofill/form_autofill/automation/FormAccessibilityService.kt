package com.formautofill.form_autofill.automation

import android.accessibilityservice.AccessibilityService
import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.formautofill.form_autofill.engine.AccessibilityEventManager
import com.formautofill.form_autofill.engine.FieldFiller
import com.formautofill.form_autofill.engine.FormMappingEngine
import com.formautofill.form_autofill.engine.ScrollManager
import com.formautofill.form_autofill.ocr.OcrService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Main Accessibility Service — orchestrates detection, OCR, scroll, and fill.
 */
class FormAccessibilityService : AccessibilityService() {

    private val tag = "FormAccessibility"
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private val running = AtomicBoolean(false)

    private lateinit var eventManager: AccessibilityEventManager
    private lateinit var scrollManager: ScrollManager
    private lateinit var fieldFiller: FieldFiller
    private val ocrService = OcrService()

    private val filledKeys = mutableSetOf<String>()
    private var scrollAttempts = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        eventManager = AccessibilityEventManager()
        scrollManager = ScrollManager(this)
        fieldFiller = FieldFiller(this)
        AutomationController.bindService(this)
        Log.i(tag, "Accessibility service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || !running.get()) return
        if (!eventManager.shouldReactToEvent(event)) return
    }

    override fun onInterrupt() {
        stopAutomationLoop()
    }

    override fun onDestroy() {
        ocrService.shutdown()
        executor.shutdownNow()
        AutomationController.unbindService()
        super.onDestroy()
    }

    fun startAutomationLoop() {
        if (running.getAndSet(true)) return
        filledKeys.clear()
        scrollAttempts = 0
        scrollManager.scrollCount = 0
        executor.execute { runFillCycle() }
    }

    fun stopAutomationLoop() {
        running.set(false)
        handler.removeCallbacksAndMessages(null)
    }

    private fun runFillCycle() {
        val totalFields = AutomationController.fieldData.size
        var retriesWithoutProgress = 0

        while (running.get() && !AutomationController.stopRequested) {
            if (AutomationController.paused) {
                Thread.sleep(300)
                continue
            }

            val root = rootInActiveWindow
            if (root == null) {
                Thread.sleep(AutomationController.retryDelayMs)
                continue
            }

            AutomationController.emitStatus(
                "scanning",
                "Detecting fields…",
                filledKeys.size,
                totalFields,
                scrollManager.scrollCount
            )

            var labelTexts = eventManager.collectLabelTexts(root)
            val editNodes = eventManager.collectEditableNodes(root)

            // OCR supplement when few labels found
            if (labelTexts.size < 3) {
                captureScreenshot()?.let { bitmap ->
                    try {
                        val ocrLabels = ocrService.extractLabels(
                            bitmap,
                            AutomationController.ocrThreshold
                        )
                        labelTexts = (labelTexts + ocrLabels).distinctBy { it.first }
                        bitmap.recycle()
                    } catch (e: Exception) {
                        Log.w(tag, "OCR capture failed", e)
                    }
                }
            }

            val mapper = FormMappingEngine(AutomationController.fieldData)
            val mapped = mapper.mapFields(editNodes, labelTexts)
                .filter { !filledKeys.contains(it.key) }

            if (mapped.isEmpty()) {
                retriesWithoutProgress++
                if (retriesWithoutProgress >= 3 &&
                    scrollAttempts < AutomationController.maxScrollRetries
                ) {
                    AutomationController.emitStatus(
                        "scrolling",
                        "Scrolling to find more fields…",
                        filledKeys.size,
                        totalFields,
                        scrollManager.scrollCount
                    )
                    val metrics = resources.displayMetrics
                    val scrolled = scrollManager.scrollDown(root, metrics)
                    scrollAttempts++
                    Thread.sleep(AutomationController.scrollDelayMs)
                    if (!scrolled) retriesWithoutProgress = 0
                    continue
                } else if (filledKeys.size >= totalFields || scrollAttempts >= AutomationController.maxScrollRetries) {
                    AutomationController.emitStatus(
                        "completed",
                        "Auto-fill finished",
                        filledKeys.size,
                        totalFields,
                        scrollManager.scrollCount
                    )
                    running.set(false)
                    AutomationController.startRequested = false
                    break
                }
                Thread.sleep(AutomationController.retryDelayMs)
                continue
            }

            retriesWithoutProgress = 0

            for (field in mapped) {
                if (!running.get() || AutomationController.stopRequested) break
                AutomationController.emitStatus(
                    if (field.isDropdown) "waitingDropdown" else "filling",
                    "Filling ${field.label}",
                    filledKeys.size,
                    totalFields,
                    scrollManager.scrollCount
                )

                val success = if (field.isDropdown) {
                    fieldFiller.selectDropdown(field.node, field.value)
                } else {
                    fieldFiller.fillTextField(field.node, field.value)
                }

                if (success) {
                    filledKeys.add(field.key)
                    Log.i(tag, "Filled ${field.key} = ${field.value}")
                } else {
                    Log.w(tag, "Failed to fill ${field.key}, will retry")
                }
                Thread.sleep(250)
            }

            AutomationController.emitStatus(
                "filling",
                "Progress: ${filledKeys.size}/$totalFields",
                filledKeys.size,
                totalFields,
                scrollManager.scrollCount
            )

            if (filledKeys.size < totalFields &&
                scrollAttempts < AutomationController.maxScrollRetries
            ) {
                scrollManager.scrollDown(root, resources.displayMetrics)
                scrollAttempts++
                Thread.sleep(AutomationController.scrollDelayMs)
            } else if (filledKeys.size >= totalFields) {
                AutomationController.emitStatus(
                    "completed",
                    "All fields filled",
                    filledKeys.size,
                    totalFields,
                    scrollManager.scrollCount
                )
                running.set(false)
                break
            }
        }
    }

    private fun captureScreenshot(): Bitmap? {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.R) {
            return null
        }
        val latch = java.util.concurrent.CountDownLatch(1)
        val ref = java.util.concurrent.atomic.AtomicReference<Bitmap?>(null)
        try {
            takeScreenshot(
                android.view.Display.DEFAULT_DISPLAY,
                executor,
                object : TakeScreenshotCallback {
                    override fun onSuccess(result: ScreenshotResult) {
                        try {
                            val hw = result.hardwareBuffer
                            ref.set(Bitmap.wrapHardwareBuffer(hw, result.colorSpace))
                        } catch (e: Exception) {
                            Log.w(tag, "Screenshot decode failed", e)
                        } finally {
                            result.hardwareBuffer.close()
                            latch.countDown()
                        }
                    }

                    override fun onFailure(errorCode: Int) {
                        latch.countDown()
                    }
                }
            )
            latch.await(5, java.util.concurrent.TimeUnit.SECONDS)
        } catch (e: Exception) {
            Log.w(tag, "Screenshot not available", e)
        }
        return ref.get()
    }
}
