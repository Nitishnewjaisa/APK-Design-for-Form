import '../entities/form_profile.dart';

abstract class ProfileRepository {
  Future<List<FormProfile>> getAllProfiles();
  Future<FormProfile?> getActiveProfile();
  Future<void> saveProfile(FormProfile profile);
  Future<void> deleteProfile(String id);
  Future<void> setActiveProfile(String id);
  Future<Map<String, String>> getActiveFieldMap();
}
