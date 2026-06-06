/// Shared fuzzy label matching for all platforms (OCR + DOM + a11y).
class LabelMatcher {
  static const Map<String, List<String>> synonyms = {
    'father_name': [
      'father name',
      'father\'s name',
      'fathers name',
      'father',
      'पिता',
    ],
    'mother_name': [
      'mother name',
      'mother\'s name',
      'mothers name',
      'mother',
      'माता',
    ],
    'gender': ['gender', 'sex', 'लिंग'],
    'address': [
      'address',
      'residential address',
      'permanent address',
      'current address',
      'पता',
    ],
    'dob': ['dob', 'date of birth', 'birth date', 'जन्म तिथि'],
    'district': ['district', 'जिला'],
    'full_name': ['full name', 'name', 'applicant name', 'नाम'],
    'email': ['email', 'e-mail'],
    'phone': ['phone', 'mobile', 'contact', 'mobile number'],
    'pincode': ['pincode', 'pin code', 'postal code'],
    'state': ['state', 'राज्य'],
    'city': ['city', 'town', 'शहर'],
    'aadhaar': ['aadhaar', 'aadhar', 'uid'],
    'pan': ['pan', 'pan card'],
  };

  static String? matchLabel(String rawLabel, {int minScore = 55}) {
    final normalized = _normalize(rawLabel);
    if (normalized.isEmpty) return null;

    String? bestKey;
    var bestScore = 0;

    for (final entry in synonyms.entries) {
      for (final synonym in entry.value) {
        final score = _score(normalized, _normalize(synonym));
        if (score > bestScore) {
          bestScore = score;
          bestKey = entry.key;
        }
      }
    }

    return bestScore >= minScore ? bestKey : null;
  }

  static String _normalize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static int _score(String a, String b) {
    if (a == b) return 100;
    if (a.contains(b) || b.contains(a)) return 85;
    final aTokens = a.split(' ');
    final bTokens = b.split(' ');
    var matches = 0;
    for (final t in aTokens) {
      if (bTokens.any((bt) => bt == t || bt.startsWith(t) || t.startsWith(bt))) {
        matches++;
      }
    }
    if (aTokens.isEmpty) return 0;
    return ((matches / aTokens.length) * 100).round();
  }
}
