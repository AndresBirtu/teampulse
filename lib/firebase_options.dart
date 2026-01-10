import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for supported platforms.
/// Currently only web is defined; mobile uses bundled google-services files.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'DefaultFirebaseOptions are not set for this platform. '
      'Mobile uses google-services.json / GoogleService-Info.plist.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_Ob7WnF6DaNf8qGiyMcEFWTGo5xkER44',
    authDomain: 'coachup-980de.firebaseapp.com',
    projectId: 'coachup-980de',
    storageBucket: 'coachup-980de.firebasestorage.app',
    messagingSenderId: '417071398695',
    appId: '1:417071398695:web:3134747f37814102333302',
  );
}
