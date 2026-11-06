import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plataforma no configurada para Firebase.');
    }
  }

  // Reemplaza estos valores con `flutterfire configure`.
  static const web = FirebaseOptions(
    apiKey: 'REEMPLAZAR_API_KEY',
    appId: 'REEMPLAZAR_APP_ID',
    messagingSenderId: 'REEMPLAZAR_SENDER_ID',
    projectId: 'REEMPLAZAR_PROJECT',
    databaseURL: 'https://REEMPLAZAR_PROJECT-default-rtdb.firebaseio.com',
  );
  static const android = web;
  static const ios = web;
}
