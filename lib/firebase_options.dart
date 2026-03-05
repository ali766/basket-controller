import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDr78eta_v2AOxrll2mTX8noI805qPtifA',
    appId: '1:760753992927:android:8702569c9c7c45be7fe56a',
    messagingSenderId: '760753992927',
    projectId: 'ok-new-7c868',
    databaseURL: 'https://ok-new-7c868-default-rtdb.firebaseio.com',
    storageBucket: 'ok-new-7c868.firebasestorage.app',
  );
}
