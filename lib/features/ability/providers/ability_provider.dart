import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ability_state.dart';
import '../../profile/providers/profile_provider.dart';

// Tracks ability state for current quiz/battle session
class AbilityNotifier extends Notifier<AbilityState> {
  @override
  AbilityState build() {
    // Don't watch profileProvider here — just return default
    // initForSolo() and initForBattle() set the real state
    return const AbilityState(
      type: AbilityType.none,
      used: false,
      available: false,
    );
  }

  // Call this when entering solo quiz
  void initForSolo() {
    final profile = ref.read(profileProvider).value;
    final characterKey = profile?.selectedCharacter ?? 'alex';
    final type = AbilityState.fromCharacterKey(characterKey);
    state = AbilityState(
      type: type,
      used: false,
      available: type != AbilityType.sabotage, // Luna not available in solo
    );
  }

  // Call this when entering 1v1 battle
  void initForBattle() {
    final profile = ref.read(profileProvider).value;
    final characterKey = profile?.selectedCharacter ?? 'alex';
    final type = AbilityState.fromCharacterKey(characterKey);
    state = AbilityState(
      type: type,
      used: false,
      available: true, // all abilities available in 1v1
    );
  }

  void markUsed() {
    state = AbilityState(
      type: state.type,
      used: true,
      available: state.available,
    );
  }

  void reset() {
    state = AbilityState(
      type: state.type,
      used: false,
      available: state.available,
    );
  }
}

final abilityProvider = NotifierProvider<AbilityNotifier, AbilityState>(
  AbilityNotifier.new,
);
