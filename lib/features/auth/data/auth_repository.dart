import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;
  const AuthRepository(this._client);

  // ── Register ──────────────────────────────────────────────────────────────
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    if (response.user != null) {
      // Sign in immediately so auth.uid() is active before insert
      await _client.auth.signInWithPassword(email: email, password: password);

      await _client.from('profiles').insert({
        'id': response.user!.id,
        'username': username,
        'role': 'scholar',
        'level': 1,
        'xp': 0,
        'coins': 100,
        'selected_character': 'joy',
      });
    }

    return response;
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async => await _client.auth.signOut();

  // ── Current session ───────────────────────────────────────────────────────
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  // ── Auth state stream (listen for login/logout changes) ───────────────────
  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;
}
