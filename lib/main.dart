import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/job_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/location_provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env').catchError((_) {
    debugPrint('No .env file found — running in Demo Mode');
  });

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.surface,
  ));

  final contactProvider = ContactProvider();
  await contactProvider.load();
  final locationProvider = LocationProvider();
  await locationProvider.load();

  runApp(CallPilotApp(contactProvider: contactProvider, locationProvider: locationProvider));
}

class CallPilotApp extends StatelessWidget {
  final ContactProvider contactProvider;
  final LocationProvider locationProvider;
  const CallPilotApp({super.key, required this.contactProvider, required this.locationProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider.value(value: contactProvider),
        ChangeNotifierProvider.value(value: locationProvider),
        ChangeNotifierProvider(create: (_) => JobProvider()),
      ],
      child: MaterialApp(
        title: 'CallPilot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}