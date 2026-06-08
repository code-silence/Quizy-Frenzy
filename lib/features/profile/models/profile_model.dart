class ProfileModel {
  final String id;
  final String username;
  final String role;
  final int level;
  final int xp;
  final int coins;
  final String selectedCharacter;

  const ProfileModel({
    required this.id,
    required this.username,
    required this.role,
    required this.level,
    required this.xp,
    required this.coins,
    required this.selectedCharacter,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      username: map['username'] as String,
      role: map['role'] as String,
      level: map['level'] as int,
      xp: map['xp'] as int,
      coins: map['coins'] as int,
      selectedCharacter: map['selected_character'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'level': level,
      'xp': xp,
      'coins': coins,
      'selected_character': selectedCharacter,
    };
  }

  // For partial updates
  ProfileModel copyWith({
    String? username,
    String? role,
    int? level,
    int? xp,
    int? coins,
    String? selectedCharacter,
  }) {
    return ProfileModel(
      id: id,
      username: username ?? this.username,
      role: role ?? this.role,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
    );
  }

  // XP needed to reach next level (simple formula)
  int get xpForNextLevel => level * 100;
  double get xpProgress => (xp % xpForNextLevel) / xpForNextLevel;
}