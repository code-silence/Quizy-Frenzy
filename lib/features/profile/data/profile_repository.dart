import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final SupabaseClient _client;
  const ProfileRepository(this._client);

  // Fetch current user's profile
  Future<ProfileModel> fetchProfile(String userId) async {
    final data =
        await _client.from('profiles').select().eq('id', userId).single();
    return ProfileModel.fromMap(data);
  }

  // Update username
  Future<void> updateUsername(String userId, String username) async {
    await _client
        .from('profiles')
        .update({'username': username})
        .eq('id', userId);
  }

  // Update selected character
  Future<void> updateCharacter(String userId, String characterKey) async {
    await _client
        .from('profiles')
        .update({'selected_character': characterKey})
        .eq('id', userId);
  }

  // Update XP and level
  Future<void> updateXpAndLevel(String userId, int xp, int level) async {
    await _client
        .from('profiles')
        .update({'xp': xp, 'level': level})
        .eq('id', userId);
  }

  // Update XP, coins, and level together
  Future<void> updateXpCoinsAndLevel(
    String userId, {
    required int xp,
    required int coins,
    required int level,
  }) async {
    await _client
        .from('profiles')
        .update({'xp': xp, 'coins': coins, 'level': level})
        .eq('id', userId);
  }
}
