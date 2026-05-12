import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../shared/models/profile.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<Profile?>>((ref) {
      return ProfileNotifier();
    });

class ProfileNotifier extends StateNotifier<AsyncValue<Profile?>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    loadProfile();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    try {
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb ? "BEHR53uXDXk2vjkmto9-QOD4n1IjpQH0A5eEdcAHU7K8eMjfZ3ORGedkit2usHXaAL0H-xr6veIxMIIvyP7IQ3g" : null,
      );
      debugPrint('FCM Token: $token');
      if (token != null) {
        await _updateFCMToken(token);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen(_updateFCMToken);
    } catch (e) {
      debugPrint('FCM setup failed: $e');
    }
  }

  Future<void> _updateFCMToken(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('profiles').update({'fcm_token': token}).eq('id', user.id);
  }

  final _supabase = Supabase.instance.client;

  Future<void> loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      state = AsyncValue.data(Profile.fromJson(response));
      _setupFCM(); // Panggil ulang di sini agar token pasti terupdate setelah login
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      await loadProfile();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  Future<String?> signUp(String email, String password, String username) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      // Profile is created via trigger
      await loadProfile();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? role,
    String? avatarUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final updates = {
      'username': ?username,
      'first_name': ?firstName,
      'last_name': ?lastName,
      'role': ?role,
      'avatar_url': ?avatarUrl,
    };

    try {
      await _supabase.from('profiles').update(updates).eq('id', user.id);
      await loadProfile();
    } catch (e) {
      // Handle error
    }
  }
}
