import 'package:uuid/uuid.dart';

import '../../domain/entities/form_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// Seeds a demo profile on first launch when no profiles exist.
Future<void> seedDefaultProfileIfNeeded(ProfileRepository repo) async {
  final existing = await repo.getAllProfiles();
  if (existing.isNotEmpty) return;

  final profile = FormProfile(
    id: const Uuid().v4(),
    name: 'Demo Profile',
    fields: const {
      'father_name': 'Ramesh Kumar',
      'mother_name': 'Sunita Devi',
      'gender': 'Male',
      'address': '123 Main Street, Sector 5',
      'dob': '15/08/1995',
      'district': 'Patna',
      'full_name': 'Nitish Kumar',
      'email': 'demo@example.com',
      'phone': '9876543210',
    },
    updatedAt: DateTime.now(),
  );

  await repo.saveProfile(profile);
  await repo.setActiveProfile(profile.id);
}
