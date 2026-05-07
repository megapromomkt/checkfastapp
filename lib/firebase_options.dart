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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AGUARDANDO_CHAVE_WEB',
    appId: 'AGUARDANDO_APP_ID_WEB',
    messagingSenderId: 'AGUARDANDO_SENDER_ID',
    projectId: 'checkfast-28a72',
    authDomain: 'checkfast-28a72.firebaseapp.com',
    storageBucket: 'checkfast-28a72.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AGUARDANDO_CHAVE_ANDROID',
    appId: 'AGUARDANDO_APP_ID_ANDROID',
    messagingSenderId: 'AGUARDANDO_SENDER_ID',
    projectId: 'checkfast-28a72',
    storageBucket: 'checkfast-28a72.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AGUARDANDO_CHAVE_IOS',
    appId: 'AGUARDANDO_APP_ID_IOS',
    messagingSenderId: 'AGUARDANDO_SENDER_ID',
    projectId: 'checkfast-28a72',
    storageBucket: 'checkfast-28a72.firebasestorage.app',
    iosBundleId: 'com.megapromo.checkfast',
  );
}
