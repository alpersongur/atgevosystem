// File generated manually for demo Firebase project configuration.
// Replace the placeholder values below with actual Firebase project settings.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the atgevo-demo Firebase project.
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'please update firebase_options_demo.dart.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDGi87KLodoNEelHLbhgo78Tta1zZe3MwI',
    appId: '1:465022829345:web:a36988eed4fcb92cd7f460',
    messagingSenderId: '465022829345',
    projectId: 'atgevo-demo',
    authDomain: 'atgevo-demo.firebaseapp.com',
    storageBucket: 'atgevo-demo.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGi87KLodoNEelHLbhgo78Tta1zZe3MwI',
    appId: '1:465022829345:android:demoappplaceholder',
    messagingSenderId: '465022829345',
    projectId: 'atgevo-demo',
    storageBucket: 'atgevo-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDGi87KLodoNEelHLbhgo78Tta1zZe3MwI',
    appId: '1:465022829345:ios:demoappplaceholder',
    messagingSenderId: '465022829345',
    projectId: 'atgevo-demo',
    storageBucket: 'atgevo-demo.appspot.com',
    iosBundleId: 'com.example.atgevodemo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDGi87KLodoNEelHLbhgo78Tta1zZe3MwI',
    appId: '1:465022829345:ios:demoappplaceholder',
    messagingSenderId: '465022829345',
    projectId: 'atgevo-demo',
    storageBucket: 'atgevo-demo.appspot.com',
    iosBundleId: 'com.example.atgevodemo',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDGi87KLodoNEelHLbhgo78Tta1zZe3MwI',
    appId: '1:465022829345:web:a36988eed4fcb92cd7f460',
    messagingSenderId: '465022829345',
    projectId: 'atgevo-demo',
    authDomain: 'atgevo-demo.firebaseapp.com',
    storageBucket: 'atgevo-demo.appspot.com',
  );
}
