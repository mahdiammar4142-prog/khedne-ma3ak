// Run `flutterfire configure` to replace with your Firebase project.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return android;
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAnWV-zjLaYIicxqa6HPqFEy8ACmrI50LY',
    appId: '1:884022766943:web:99eb5d39b670476c6d5aea',
    messagingSenderId: '884022766943',
    projectId: 'applebanon-c5bdc',
    authDomain: 'applebanon-c5bdc.firebaseapp.com',
    storageBucket: 'applebanon-c5bdc.firebasestorage.app',
    measurementId: 'G-8BXWKYEHZE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDH86CASmK33U04QKd9j4X79JQPzNTUEH8',
    appId: '1:884022766943:android:69a5c9d4c9a4f1046d5aea',
    messagingSenderId: '884022766943',
    projectId: 'applebanon-c5bdc',
    storageBucket: 'applebanon-c5bdc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDooSUGSf63Ghq02_iIhtnmwMDs4HlWS6c',
    appId: '1:406099696497:ios:acd9c8e17b5e620e3574d0',
    messagingSenderId: '406099696497',
    projectId: 'flutterfire-e2e-tests',
    storageBucket: 'flutterfire-e2e-tests.appspot.com',
    iosBundleId: 'io.flutter.plugins.firebase.tests',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDooSUGSf63Ghq02_iIhtnmwMDs4HlWS6c',
    appId: '1:406099696497:ios:acd9c8e17b5e620e3574d0',
    messagingSenderId: '406099696497',
    projectId: 'flutterfire-e2e-tests',
    storageBucket: 'flutterfire-e2e-tests.appspot.com',
    iosBundleId: 'io.flutter.plugins.firebase.tests',
  );
}