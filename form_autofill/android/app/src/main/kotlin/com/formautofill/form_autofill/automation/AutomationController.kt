package com.formautofill.form_autofill.automation

/**
 * Global controller bridging Flutter MethodChannel and AccessibilityService.
 */
object AutomationController {
    var statusListener: ((Map<String, Any?>) -> Unit)? = null

    @Volatile var startRequested = false

    @Volatile var stopRequested = false

    @Volatile var paused = false

    var fieldData: Map<String, String> = emptyMap()
    var maxScrollRetries = 8
    var scrollDelayMs = 600L
    var retryDelayMs = 400L
    var ocrThreshold = 65

    private var serviceInstance: FormAccessibilityService? = null

    fun bindService(service: FormAccessibilityService) {
        serviceInstance = service
        if (startRequested) {
            service.startAutomationLoop()
        }
    }

    fun unbindService() {
        serviceInstance = null
    }

    fun configure(
        fields: Map<String, String>,
        maxScrollRetries: Int,
        scrollDelayMs: Long,
        retryDelayMs: Long,
        ocrThreshold: Int
    ) {
        fieldData = fields
        this.maxScrollRetries = maxScrollRetries
        this.scrollDelayMs = scrollDelayMs
        this.retryDelayMs = retryDelayMs
        this.ocrThreshold = ocrThreshold
    }

    fun requestStart() {
        stopRequested = false
        paused = false
        startRequested = true
        serviceInstance?.startAutomationLoop()
    }

    fun requestStop() {
        stopRequested = true
        startRequested = false
        serviceInstance?.stopAutomationLoop()
        emitStatus("stopped", "Stopped by user")
    }

    fun requestPause() {
        paused = true
    }

    fun requestResume() {
        paused = false
    }

    fun emitStatus(
        state: String,
        message: String = "",
        fieldsFilled: Int = 0,
        fieldsTotal: Int = 0,
        scrollCount: Int = 0
    ) {
        statusListener?.invoke(
            mapOf(
                "state" to state,
                "message" to message,
                "fieldsFilled" to fieldsFilled,
                "fieldsTotal" to fieldsTotal,
                "scrollCount" to scrollCount
            )
        )
    }
}
