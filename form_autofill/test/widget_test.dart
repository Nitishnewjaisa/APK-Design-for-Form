import 'package:flutter_test/flutter_test.dart';
import 'package:form_autofill/core/utils/label_matcher.dart';

void main() {
  test('LabelMatcher matches father name', () {
    expect(LabelMatcher.matchLabel('Father\'s Name'), 'father_name');
  });

  test('LabelMatcher matches district', () {
    expect(LabelMatcher.matchLabel('District'), 'district');
  });

  test('LabelMatcher returns null for unknown', () {
    expect(LabelMatcher.matchLabel('Random Field XYZ 123'), isNull);
  });
}
