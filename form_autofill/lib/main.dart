import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/utils/default_profile_seed.dart';
import 'data/datasources/profile_local_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveProfilesBox);
  await Hive.openBox(AppConstants.hiveLogsBox);
  await Hive.openBox(AppConstants.hivePrefsBox);

  final profilesBox = Hive.box(AppConstants.hiveProfilesBox);
  final profileRepo = ProfileRepositoryImpl(
    ProfileLocalDatasource(profilesBox),
  );
  await seedDefaultProfileIfNeeded(profileRepo);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const FormAutoFillApp());
}

class FormAutoFillApp extends StatelessWidget {
  const FormAutoFillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildProviders(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
