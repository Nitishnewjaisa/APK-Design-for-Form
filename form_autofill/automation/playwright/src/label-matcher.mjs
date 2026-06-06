const SYNONYMS = {
  father_name: ['father name', "father's name", 'father'],
  mother_name: ['mother name', "mother's name", 'mother'],
  gender: ['gender', 'sex'],
  address: ['address', 'residential address', 'permanent address'],
  dob: ['dob', 'date of birth', 'birth date'],
  district: ['district'],
  full_name: ['full name', 'name', 'applicant name'],
  email: ['email', 'e-mail'],
  phone: ['phone', 'mobile', 'contact'],
  pincode: ['pincode', 'pin code'],
  state: ['state'],
  city: ['city', 'town'],
  aadhaar: ['aadhaar', 'aadhar'],
  pan: ['pan', 'pan card'],
};

function normalize(s) {
  return s.toLowerCase().replace(/[^\w\s]/g, ' ').replace(/\s+/g, ' ').trim();
}

export function matchLabel(raw, minScore = 55) {
  const n = normalize(raw);
  if (!n) return null;
  let bestKey = null;
  let bestScore = 0;
  for (const [key, terms] of Object.entries(SYNONYMS)) {
    for (const term of terms) {
      const t = normalize(term);
      let score = 0;
      if (n === t) score = 100;
      else if (n.includes(t) || t.includes(n)) score = 85;
      else {
        const a = n.split(' ');
        const b = t.split(' ');
        const matches = a.filter((x) => b.some((y) => y === x || y.startsWith(x))).length;
        score = Math.round((matches / a.length) * 100);
      }
      if (score > bestScore) {
        bestScore = score;
        bestKey = key;
      }
    }
  }
  return bestScore >= minScore ? bestKey : null;
}
