package com.formautofill.form_autofill.engine

/**
 * Native label matching for accessibility text and OCR blocks.
 */
object LabelMatcherEngine {
    private val synonyms = mapOf(
        "father_name" to listOf("father name", "father's name", "fathers name", "father", "पिता"),
        "mother_name" to listOf("mother name", "mother's name", "mothers name", "mother", "माता"),
        "gender" to listOf("gender", "sex", "लिंग"),
        "address" to listOf("address", "residential address", "permanent address", "पता"),
        "dob" to listOf("dob", "date of birth", "birth date", "जन्म तिथि"),
        "district" to listOf("district", "जिला"),
        "full_name" to listOf("full name", "name", "applicant name", "नाम"),
        "email" to listOf("email", "e-mail"),
        "phone" to listOf("phone", "mobile", "contact", "mobile number"),
        "pincode" to listOf("pincode", "pin code", "postal code"),
        "state" to listOf("state", "राज्य"),
        "city" to listOf("city", "town", "शहर"),
        "aadhaar" to listOf("aadhaar", "aadhar", "uid"),
        "pan" to listOf("pan", "pan card")
    )

    fun matchLabel(rawLabel: String, minScore: Int = 55): String? {
        val normalized = normalize(rawLabel)
        if (normalized.isEmpty()) return null
        var bestKey: String? = null
        var bestScore = 0
        for ((key, terms) in synonyms) {
            for (term in terms) {
                val score = score(normalized, normalize(term))
                if (score > bestScore) {
                    bestScore = score
                    bestKey = key
                }
            }
        }
        return if (bestScore >= minScore) bestKey else null
    }

    private fun normalize(input: String): String =
        input.lowercase()
            .replace(Regex("[^\\w\\s]"), " ")
            .replace(Regex("\\s+"), " ")
            .trim()

    private fun score(a: String, b: String): Int {
        if (a == b) return 100
        if (a.contains(b) || b.contains(a)) return 85
        val aTokens = a.split(" ")
        val bTokens = b.split(" ")
        var matches = 0
        for (t in aTokens) {
            if (bTokens.any { bt -> bt == t || bt.startsWith(t) || t.startsWith(bt) }) matches++
        }
        if (aTokens.isEmpty()) return 0
        return ((matches.toDouble() / aTokens.size) * 100).toInt()
    }
}
