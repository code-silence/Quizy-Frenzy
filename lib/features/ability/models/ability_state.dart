enum AbilityType { hint, doubleHint, extraTime, retry, sabotage, none }

class AbilityState {
  final AbilityType type;
  final bool used;
  final bool available; // false if Luna in solo mode

  const AbilityState({
    required this.type,
    required this.used,
    required this.available,
  });

  bool get canUse => !used && available && type != AbilityType.none;

  static AbilityType fromCharacterKey(String key) {
    switch (key) {
      case 'joy': return AbilityType.hint;
      case 'maya': return AbilityType.doubleHint;
      case 'rik': return AbilityType.extraTime;
      case 'raka': return AbilityType.retry;
      case 'luna': return AbilityType.sabotage;
      default: return AbilityType.none;
    }
  }

  static String abilityLabel(AbilityType type) {
    switch (type) {
      case AbilityType.hint: return 'Hint';
      case AbilityType.doubleHint: return 'Double Hint';
      case AbilityType.extraTime: return 'Extra Time';
      case AbilityType.retry: return 'Retry';
      case AbilityType.sabotage: return 'Sabotage';
      case AbilityType.none: return '';
    }
  }

  static String abilityIcon(AbilityType type) {
    switch (type) {
      case AbilityType.hint: return '💡';
      case AbilityType.doubleHint: return '🔍';
      case AbilityType.extraTime: return '⏱️';
      case AbilityType.retry: return '🔄';
      case AbilityType.sabotage: return '⚡';
      case AbilityType.none: return '';
    }
  }
}