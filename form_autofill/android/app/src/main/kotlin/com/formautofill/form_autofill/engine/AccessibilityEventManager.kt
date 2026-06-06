package com.formautofill.form_autofill.engine

import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Collects editable nodes and static label text from the accessibility tree.
 */
class AccessibilityEventManager {

    fun collectEditableNodes(root: AccessibilityNodeInfo?): List<AccessibilityNodeInfo> {
        val result = mutableListOf<AccessibilityNodeInfo>()
        if (root == null) return result
        traverseForEditables(root, result)
        return result.distinctBy { it.hashCode() }
    }

    fun collectLabelTexts(root: AccessibilityNodeInfo?): List<Pair<String, android.graphics.Rect>> {
        val result = mutableListOf<Pair<String, android.graphics.Rect>>()
        if (root == null) return result
        traverseForLabels(root, result)
        return result
    }

    private fun traverseForEditables(node: AccessibilityNodeInfo, out: MutableList<AccessibilityNodeInfo>) {
        val cls = node.className?.toString()?.lowercase() ?: ""
        val isInput = node.isEditable ||
            cls.contains("edittext") ||
            cls.contains("autocomplete") ||
            (node.isClickable && cls.contains("spinner"))

        if (isInput && node.isVisibleToUser) {
            out.add(node)
        }
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { traverseForEditables(it, out) }
        }
    }

    private fun traverseForLabels(
        node: AccessibilityNodeInfo,
        out: MutableList<Pair<String, android.graphics.Rect>>
    ) {
        val text = node.text?.toString()?.trim() ?: ""
        val desc = node.contentDescription?.toString()?.trim() ?: ""
        val label = when {
            text.isNotBlank() && text.length < 80 -> text
            desc.isNotBlank() && desc.length < 80 -> desc
            else -> ""
        }
        if (label.isNotBlank() && !node.isEditable) {
            val bounds = android.graphics.Rect()
            node.getBoundsInScreen(bounds)
            if (bounds.height() in 1..200) {
                out.add(label to bounds)
            }
        }
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { traverseForLabels(it, out) }
        }
    }

    fun shouldReactToEvent(event: AccessibilityEvent): Boolean {
        return when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> true
            else -> false
        }
    }
}
