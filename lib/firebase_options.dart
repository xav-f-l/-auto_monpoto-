import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyChAqmySfZTm90_iB_FfUpXdUUU1YkiHDs',
    appId: '1:150710241384:web:f5f313fd907fc15c9153dd',
    messagingSenderId: '150710241384',
    projectId: 'locationauto-c2a04',
    authDomain: 'locationauto-c2a04.firebaseapp.com',
    storageBucket: 'locationauto-c2a04.firebasestorage.app',
    measurementId: 'G-xxxxxxxxxx',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyChAqmySfZTm90_iB_FfUpXdUUU1YkiHDs',
    appId: '1:150710241384:android:f5f313fd907fc15c9153dd',
    messagingSenderId: '150710241384',
    projectId: 'locationauto-c2a04',
    storageBucket: 'locationauto-c2a04.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChAqmySfZTm90_iB_FfUpXdUUU1YkiHDs',
    appId: '1:150710241384:ios:f5f313fd907fc15c9153dd',
    messagingSenderId: '150710241384',
    projectId: 'locationauto-c2a04',
    storageBucket: 'locationauto-c2a04.firebasestorage.app',
    iosBundleId: 'com.automonpoto.auto_monpoto',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyChAqmySfZTm90_iB_FfUpXdUUU1YkiHDs',
    appId: '1:150710241384:ios:f5f313fd907fc15c9153dd',
    messagingSenderId: '150710241384',
    projectId: 'locationauto-c2a04',
    storageBucket: 'locationauto-c2a04.firebasestorage.app',
    iosBundleId: 'com.automonpoto.auto_monpoto',
  );
}
