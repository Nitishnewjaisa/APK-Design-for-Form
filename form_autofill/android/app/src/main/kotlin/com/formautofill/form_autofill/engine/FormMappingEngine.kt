package com.formautofill.form_autofill.engine

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Maps detected UI fields to stored profile data using labels and hints.
 */
class FormMappingEngine(private val fieldData: Map<String, String>) {

    data class DetectedField(
        val key: String,
        val value: String,
        val node: AccessibilityNodeInfo,
        val label: String,
        val isDropdown: Boolean,
        val bounds: Rect
    )

    fun mapFields(
        editNodes: List<AccessibilityNodeInfo>,
        labelTexts: List<Pair<String, Rect>>
    ): List<DetectedField> {
        val results = mutableListOf<DetectedField>()
        val usedKeys = mutableSetOf<String>()

        for (node in editNodes) {
            val hint = node.hintText?.toString() ?: ""
            val desc = node.contentDescription?.toString() ?: ""
            val text = node.text?.toString() ?: ""
            val nearbyLabel = findNearestLabel(node, labelTexts)

            val candidates = listOf(hint, desc, nearbyLabel, text).filter { it.isNotBlank() }
            var matchedKey: String? = null
            var matchedLabel = ""

            for (candidate in candidates) {
                matchedKey = LabelMatcherEngine.matchLabel(candidate)
                if (matchedKey != null) {
                    matchedLabel = candidate
                    break
                }
            }

            if (matchedKey == null || usedKeys.contains(matchedKey)) continue
            val value = fieldData[matchedKey] ?: continue
            if (value.isBlank()) continue

            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            val isDropdown = isSpinnerOrDropdown(node)

            results.add(
                DetectedField(
                    key = matchedKey,
                    value = value,
                    node = node,
                    label = matchedLabel.ifBlank { matchedKey },
                    isDropdown = isDropdown,
                    bounds = bounds
                )
            )
            usedKeys.add(matchedKey)
        }
        return results
    }

    private fun findNearestLabel(
        node: AccessibilityNodeInfo,
        labels: List<Pair<String, Rect>>
    ): String {
        val nodeBounds = Rect()
        node.getBoundsInScreen(nodeBounds)
        var best = ""
        var bestDist = Int.MAX_VALUE
        for ((text, rect) in labels) {
            if (rect.bottom > nodeBounds.top + 50) continue
            val dy = nodeBounds.top - rect.bottom
            val dx = kotlin.math.abs(nodeBounds.left - rect.left)
            val dist = dy + dx
            if (dist in 0 until bestDist) {
                bestDist = dist
                best = text
            }
        }
        return best
    }

    private fun isSpinnerOrDropdown(node: AccessibilityNodeInfo): Boolean {
        val cls = node.className?.toString()?.lowercase() ?: ""
        if (cls.contains("spinner") || cls.contains("dropdown")) return true
        if (node.isClickable && !node.isEditable) return true
        val parent = node.parent
        if (parent != null) {
            val pCls = parent.className?.toString()?.lowercase() ?: ""
            if (pCls.contains("spinner")) return true
        }
        return false
    }
}
