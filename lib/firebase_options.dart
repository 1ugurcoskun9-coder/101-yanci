import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAzkbqwSrnHr23TdCKUw-3zSrGPj1vxsic',
    authDomain: 'yanci-3d299.firebaseapp.com',
    projectId: 'yanci-3d299',
    storageBucket: 'yanci-3d299.firebasestorage.app',
    messagingSenderId: '588485310238',
    appId: '1:588485310238:web:89f17d1456e6ea6fbcbb0f',
    measurementId: 'G-0XGK3SYVEJ',
  );
}
