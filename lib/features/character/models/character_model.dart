class CharacterModel {
  final String id;
  final String characterKey;
  final String name;
  final String gender;
  final int unlockLevel;
  final String? abilityName;
  final String? abilityDescription;
  final int abilityUses;

  const CharacterModel({
    required this.id,
    required this.characterKey,
    required this.name,
    required this.gender,
    required this.unlockLevel,
    this.abilityName,
    this.abilityDescription,
    required this.abilityUses,
  });

  factory CharacterModel.fromMap(Map<String, dynamic> map) {
    return CharacterModel(
      id: map['id'] as String,
      characterKey: map['character_key'] as String,
      name: map['name'] as String,
      gender: map['gender'] as String,
      unlockLevel: map['unlock_level'] as int,
      abilityName: map['ability_name'] as String?,
      abilityDescription: map['ability_description'] as String?,
      abilityUses: map['ability_uses'] as int,
    );
  }

  bool get isFree => unlockLevel == 0;
  bool get hasAbility => abilityName != null;

  // Asset paths
  String get fullImagePath => 'assets/characters/${characterKey}_full.png';
  String get iconImagePath => 'assets/characters/${characterKey}_icon.png';

  // Card color per character
  static const Map<String, List<int>> characterColors = {
    'alex':  [0xFF4A90D9, 0xFF1A3A6B],
    'nira':  [0xFFE96BB0, 0xFF7B1A5A],
    'joy':   [0xFFFFB347, 0xFF8B4513],
    'rik':   [0xFF50C878, 0xFF1A5C2A],
    'raka':  [0xFFDA70D6, 0xFF6B1A6B],
    'maya':  [0xFFFF6B6B, 0xFF8B1A1A],
    'luna':  [0xFF9B59B6, 0xFF4A1A6B],
  };

  List<int> get colors => characterColors[characterKey] ?? [0xFF7F77DD, 0xFF3C3489];
}