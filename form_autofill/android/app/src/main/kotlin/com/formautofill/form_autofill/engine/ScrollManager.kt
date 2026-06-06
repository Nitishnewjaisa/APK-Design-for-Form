package com.formautofill.form_autofill.engine

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.util.DisplayMetrics
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Handles scrolling long forms via gestures and scrollable node actions.
 */
class ScrollManager(private val service: AccessibilityService) {

    var scrollCount = 0

    fun scrollDown(root: AccessibilityNodeInfo?, displayMetrics: DisplayMetrics): Boolean {
        if (tryScrollableNode(root)) {
            scrollCount++
            return true
        }
        return performSwipeScroll(displayMetrics)
    }

    private fun tryScrollableNode(root: AccessibilityNodeInfo?): Boolean {
        if (root == null) return false
        val scrollable = findScrollable(root)
        return scrollable?.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD) == true
    }

    private fun findScrollable(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isScrollable) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findScrollable(child)
            if (found != null) return found
        }
        return null
    }

    private fun performSwipeScroll(metrics: DisplayMetrics): Boolean {
        val midX = metrics.widthPixels / 2f
        val startY = metrics.heightPixels * 0.75f
        val endY = metrics.heightPixels * 0.25f
        val path = Path().apply {
            moveTo(midX, startY)
            lineTo(midX, endY)
        }
        val stroke = GestureDescription.StrokeDescription(path, 0, 350)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()
        return service.dispatchGesture(gesture, null, null)
    }
}
