import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/constants.dart';
import 'package:flutter/foundation.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyD-KVtmg-myJCatc2eGCwe9CBDLvSup-oc",
          authDomain: "sync-team-project.firebaseapp.com",
          projectId: "sync-team-project",
          storageBucket: "sync-team-project.firebasestorage.app",
          messagingSenderId: "1039676366270",
          appId: "1:1039676366270:web:17bdc93d2ea54f322a2def",
          measurementId: "G-4E9W3FN7E5",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    // Request permission and get token
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.notification!.title ?? 'New Notification',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(message.notification!.body ?? ''),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: SyncTeamApp(),
    ),
  );
}
