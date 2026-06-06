import '../../domain/entities/form_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDatasource _datasource;

  ProfileRepositoryImpl(this._datasource);

  @override
  Future<List<FormProfile>> getAllProfiles() => _datasource.getAll();

  @override
  Future<FormProfile?> getActiveProfile() => _datasource.getActive();

  @override
  Future<void> saveProfile(FormProfile profile) =>
      _datasource.save(profile);

  @override
  Future<void> deleteProfile(String id) => _datasource.delete(id);

  @override
  Future<void> setActiveProfile(String id) => _datasource.setActive(id);

  @override
  Future<Map<String, String>> getActiveFieldMap() async {
    final profile = await getActiveProfile();
    return profile?.fields ?? {};
  }
}
