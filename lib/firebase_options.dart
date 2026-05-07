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
    apiKey: 'AIzaSyDUK3AoHec6b_tVKxoXsZKGqisB-r29t2g',
    appId: '1:409200466931:web:a51f90e2d3314049685086',
    messagingSenderId: '409200466931',
    projectId: 'checkfast-28a72',
    authDomain: 'checkfast-28a72.firebaseapp.com',
    storageBucket: 'checkfast-28a72.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUK3AoHec6b_tVKxoXsZKGqisB-r29t2g',
    appId: '1:409200466931:android:AGUARDANDO_APP_ID_ANDROID', // Placeholder até criar o app Android
    messagingSenderId: '409200466931',
    projectId: 'checkfast-28a72',
    storageBucket: 'checkfast-28a72.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUK3AoHec6b_tVKxoXsZKGqisB-r29t2g',
    appId: '1:409200466931:ios:AGUARDANDO_APP_ID_IOS', // Placeholder até criar o app iOS
    messagingSenderId: '409200466931',
    projectId: 'checkfast-28a72',
    storageBucket: 'checkfast-28a72.firebasestorage.app',
    iosBundleId: 'com.megapromo.checkfast',
  );
}
