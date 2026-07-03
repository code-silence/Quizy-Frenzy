class MatchModel {
  final String id;
  final String? roomCode;
  final String status; // waiting | ready | in_progress | finished
  final List<String> questionIds;
  final int currentQuestionIndex;
  final DateTime? startedAt;

  const MatchModel({
    required this.id,
    required this.roomCode,
    required this.status,
    required this.questionIds,
    required this.currentQuestionIndex,
    this.startedAt,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      id: map['id'] as String,
      roomCode: map['room_code'] as String?,
      status: map['status'] as String,
      questionIds: List<String>.from(map['question_ids'] ?? []),
      currentQuestionIndex: map['current_question_index'] as int,
      startedAt:
          map['started_at'] != null ? DateTime.parse(map['started_at']) : null,
    );
  }

  bool get isWaiting => status == 'waiting';
  bool get isReady => status == 'ready';
  bool get isInProgress => status == 'in_progress';
  bool get isFinished => status == 'finished';
}

class MatchPlayerModel {
  final String id;
  final String matchId;
  final String playerId;
  final String username;
  final int score;
  final List<String?> answers;
  final bool isHost;
  final bool ready;
  final bool sabotaged;

  const MatchPlayerModel({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.username,
    required this.score,
    required this.answers,
    required this.isHost,
    required this.ready,
    required this.sabotaged,
  });

  factory MatchPlayerModel.fromMap(Map<String, dynamic> map) {
    return MatchPlayerModel(
      id: map['id'] as String,
      matchId: map['match_id'] as String,
      playerId: map['player_id'] as String,
      username: map['profiles']?['username'] ?? 'Player',
      score: map['score'] as int,
      answers: List<String?>.from(map['answers'] ?? []),
      isHost: map['is_host'] as bool,
      ready: map['ready'] as bool,
      sabotaged: map['sabotaged'] as bool? ?? false,
    );
  }
}
