import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../models/profile_model.dart';
import '../../../main.dart';
import '../../auth/providers/auth_provider.dart';

// Repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(supabase);
});

// Fetches and caches the current user's profile
final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileModel?>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<ProfileModel?> {
  @override
  Future<ProfileModel?> build() async {

      ref.watch(authStateProvider);

    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return await ref.read(profileRepositoryProvider).fetchProfile(user.id);
  }

  // Refresh profile from Supabase
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = supabase.auth.currentUser;
      if (user == null) return null;
      return await ref.read(profileRepositoryProvider).fetchProfile(user.id);
    });
  }

  // Update username locally + remotely
  Future<void> updateUsername(String username) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(username: username));
    await ref
        .read(profileRepositoryProvider)
        .updateUsername(current.id, username);
  }

  // Update character locally + remotely
  Future<void> updateCharacter(String characterKey) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedCharacter: characterKey));
    await ref
        .read(profileRepositoryProvider)
        .updateCharacter(current.id, characterKey);
  }

// Add XP and coins after a quiz, with level-up logic
Future<void> addXpAndCoins({required int xp, required int coins}) async {
  final current = state.value;
  if (current == null) return;

  final newXp = current.xp + xp;
  final newCoins = current.coins + coins;

  int newLevel = current.level;
  int remainingXp = newXp;
  while (remainingXp >= newLevel * 100) {
    remainingXp -= newLevel * 100;
    newLevel++;
  }

  // Persist to Supabase FIRST
  try {
    await ref.read(profileRepositoryProvider).updateXpCoinsAndLevel(
          current.id,
          xp: newXp,
          coins: newCoins,
          level: newLevel,
        );
    print('=== Supabase update SUCCESS ===');
  } catch (e, stack) {
    print('=== Supabase update FAILED: $e ===');
    print(stack);
    return;
  }

  // Then update local state AFTER Supabase confirms
  state = AsyncData(current.copyWith(
    xp: newXp,
    coins: newCoins,
    level: newLevel,
  ));
}
}