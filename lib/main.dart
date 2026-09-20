import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lebanon_places/core/router/app_router.dart';
import 'package:lebanon_places/core/theme/app_theme.dart';
import 'package:lebanon_places/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack?.toString() ?? '');
  };
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed (run flutterfire configure): $e');
  }
  runApp(const ProviderScope(child: LebanonPlacesApp()));
}

class LebanonPlacesApp extends StatelessWidget {
  const LebanonPlacesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Khedne Ma3ak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
