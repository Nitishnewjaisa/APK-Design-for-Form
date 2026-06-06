package com.formautofill.form_autofill.engine

import android.accessibilityservice.AccessibilityService
import android.os.Bundle
import android.view.accessibility.AccessibilityNodeInfo
import com.formautofill.form_autofill.automation.AutomationController

/**
 * Fills text fields and selects dropdown/spinner values.
 */
class FieldFiller(private val service: AccessibilityService) {

    fun fillTextField(node: AccessibilityNodeInfo, value: String): Boolean {
        node.performAction(AccessibilityNodeInfo.ACTION_FOCUS)
        val args = Bundle()
        args.putCharSequence(
            AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
            value
        )
        val set = node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
        if (set) return true
        // Fallback: paste via clipboard simulation
        return node.performAction(AccessibilityNodeInfo.ACTION_PASTE).also {
            if (!it) AutomationController.emitStatus(
                "filling",
                "Retry fill for field"
            )
        }
    }

    fun selectDropdown(node: AccessibilityNodeInfo, value: String): Boolean {
        if (!node.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
            node.parent?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        }
        Thread.sleep(400)
        val root = service.rootInActiveWindow ?: return false
        return findAndClickOption(root, value)
    }

    private fun findAndClickOption(
        node: AccessibilityNodeInfo,
        targetValue: String,
        depth: Int = 0
    ): Boolean {
        if (depth > 12) return false
        val text = node.text?.toString()?.trim() ?: ""
        val desc = node.contentDescription?.toString()?.trim() ?: ""
        val normalizedTarget = targetValue.lowercase()
        if ((text.equals(normalizedTarget, true) ||
                text.contains(normalizedTarget, true) ||
                desc.equals(normalizedTarget, true)) &&
            node.isVisibleToUser
        ) {
            if (node.performAction(AccessibilityNodeInfo.ACTION_CLICK)) return true
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (findAndClickOption(child, targetValue, depth + 1)) return true
        }
        return false
    }
}
