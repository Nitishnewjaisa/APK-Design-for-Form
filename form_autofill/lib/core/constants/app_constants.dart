class AppConstants {
  static const String appName = 'Form AutoFill Pro';
  static const String hiveBoxName = 'form_data_box';
  static const String hiveProfilesBox = 'profiles_box';
  static const String hiveLogsBox = 'debug_logs_box';
  static const String hivePrefsBox = 'app_prefs_box';
  static const String playwrightServiceUrl = 'http://127.0.0.1:3939';

  static const String channelAutomation = 'com.formautofill/automation';
  static const String channelOcr = 'com.formautofill/ocr';
  static const String channelPermissions = 'com.formautofill/permissions';

  static const int maxScrollRetries = 8;
  static const int fieldDetectionRetryMs = 400;
  static const int scrollDelayMs = 600;
  static const int ocrConfidenceThreshold = 65;
  static const int maxLogEntries = 500;

  static const List<String> defaultLabelKeys = [
    'father_name',
    'mother_name',
    'gender',
    'address',
    'dob',
    'district',
    'full_name',
    'email',
    'phone',
    'pincode',
    'state',
    'city',
    'aadhaar',
    'pan',
  ];
}
