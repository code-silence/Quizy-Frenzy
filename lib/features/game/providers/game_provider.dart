import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/game_repository.dart';
import '../models/match_model.dart';
import '../../quiz/models/question_model.dart';
import '../../quiz/providers/quiz_provider.dart';
import '../../../main.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(supabase);
});

// Current match state
class BattleState {
  final MatchModel match;
  final List<MatchPlayerModel> players;
  final List<QuestionModel> questions;
  final String? selectedAnswer;
  final bool answered;
  final int secondsLeft;
  final bool finished;

  const BattleState({
    required this.match,
    required this.players,
    required this.questions,
    required this.selectedAnswer,
    required this.answered,
    required this.secondsLeft,
    required this.finished,
  });

  QuestionModel get currentQuestion => questions[match.currentQuestionIndex];

  MatchPlayerModel? get myPlayer {
    final uid = supabase.auth.currentUser?.id;
    try {
      return players.firstWhere((p) => p.playerId == uid);
    } catch (_) {
      return null;
    }
  }

  MatchPlayerModel? get opponent {
    final uid = supabase.auth.currentUser?.id;
    try {
      return players.firstWhere((p) => p.playerId != uid);
    } catch (_) {
      return null;
    }
  }

  bool get isHost => myPlayer?.isHost ?? false;
  bool get bothPlayersJoined => players.length >= 2;

  BattleState copyWith({
    MatchModel? match,
    List<MatchPlayerModel>? players,
    String? selectedAnswer,
    bool? answered,
    int? secondsLeft,
    bool? finished,
    bool clearSelected = false,
  }) {
    return BattleState(
      match: match ?? this.match,
      players: players ?? this.players,
      questions: questions,
      selectedAnswer:
          clearSelected ? null : selectedAnswer ?? this.selectedAnswer,
      answered: answered ?? this.answered,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      finished: finished ?? this.finished,
    );
  }
}

class BattleNotifier extends AsyncNotifier<BattleState> {
  Timer? _timer;
  StreamSubscription? _matchSub;
  StreamSubscription? _playersSub;
  static const int questionTimeSeconds = 15;

  @override
  Future<BattleState> build() async {
    ref.onDispose(() {
      _timer?.cancel();
      _matchSub?.cancel();
      _playersSub?.cancel();
    });
    throw UnimplementedError();
  }

  Future<void> initBattle(MatchModel match) async {
    state = const AsyncLoading();

    final allQuestions = await ref
        .read(quizRepositoryProvider)
        .fetchQuestions(limit: match.questionIds.length);

    final players = await ref
        .read(gameRepositoryProvider)
        .fetchPlayers(match.id);

    state = AsyncData(
      BattleState(
        match: match,
        players: players,
        questions: allQuestions,
        selectedAnswer: null,
        answered: false,
        secondsLeft: questionTimeSeconds,
        finished: false,
      ),
    );

    _listenToMatch(match.id);
    _listenToPlayers(match.id);
  }

  void _listenToMatch(String matchId) {
    _matchSub = ref.read(gameRepositoryProvider).watchMatch(matchId).listen((
      updatedMatch,
    ) {
      final current = state.value;
      if (current == null) return;

      if (updatedMatch.isFinished) {
        _timer?.cancel();
        state = AsyncData(
          current.copyWith(match: updatedMatch, finished: true),
        );
        return;
      }

      // Question advanced by host
      if (updatedMatch.currentQuestionIndex !=
          current.match.currentQuestionIndex) {
        _timer?.cancel();
        state = AsyncData(
          current.copyWith(
            match: updatedMatch,
            answered: false,
            secondsLeft: questionTimeSeconds,
            clearSelected: true,
          ),
        );
        if (current.isHost) _startTimer();
      } else {
        state = AsyncData(current.copyWith(match: updatedMatch));
      }

      // Start timer when match goes in_progress
      if (updatedMatch.isInProgress &&
          !current.match.isInProgress &&
          current.isHost) {
        _startTimer();
      }
    });
  }

  void _listenToPlayers(String matchId) {
    _playersSub = ref
        .read(gameRepositoryProvider)
        .watchPlayers(matchId)
        .listen(
          (players) {
            print('=== players update received: ${players.length} players ===');
            for (final p in players) {
              print('  player: ${p.username} | host: ${p.isHost}');
            }

            final current = state.value;
            if (current == null) return;
            state = AsyncData(current.copyWith(players: players));

            print(
              '=== isWaiting: ${current.match.isWaiting} | isHost: ${current.isHost} ===',
            );

            if (players.length >= 2 &&
                current.match.isWaiting &&
                current.isHost) {
              print('=== AUTO STARTING MATCH ===');
              ref.read(gameRepositoryProvider).startMatch(matchId);
            }
          },
          onError: (e) {
            print('=== players stream ERROR: $e ===');
          },
        );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final current = state.value;
      if (current == null) return;
      if (current.secondsLeft <= 1) {
        t.cancel();
        _onTimeUp();
      } else {
        state = AsyncData(
          current.copyWith(secondsLeft: current.secondsLeft - 1),
        );
      }
    });
  }

  void _onTimeUp() {
    final current = state.value;
    if (current == null || current.answered) return;
    _submitAnswer(null);
  }

  Future<void> selectAnswer(String answer) async {
    final current = state.value;
    if (current == null || current.answered) return;
    _timer?.cancel();
    await _submitAnswer(answer);
  }

  Future<void> _submitAnswer(String? answer) async {
    final current = state.value;
    if (current == null) return;

    final myPlayer = current.myPlayer;
    if (myPlayer == null) return;

    final question = current.currentQuestion;
    final isCorrect = answer == question.correctAnswer;
    final newScore = myPlayer.score + (isCorrect ? 1 : 0);

    final updatedAnswers = List<String?>.from(myPlayer.answers);
    while (updatedAnswers.length <= current.match.currentQuestionIndex) {
      updatedAnswers.add(null);
    }
    updatedAnswers[current.match.currentQuestionIndex] = answer;

    state = AsyncData(current.copyWith(selectedAnswer: answer, answered: true));

    await ref
        .read(gameRepositoryProvider)
        .submitAnswer(
          matchId: current.match.id,
          playerId: myPlayer.playerId,
          answers: updatedAnswers,
          score: newScore,
        );

    // Host advances question after delay
    if (current.isHost) {
      await Future.delayed(const Duration(seconds: 2));
      final isLast =
          current.match.currentQuestionIndex >= current.questions.length - 1;
      if (isLast) {
        await ref.read(gameRepositoryProvider).finishMatch(current.match.id);
      } else {
        await ref
            .read(gameRepositoryProvider)
            .nextQuestion(
              current.match.id,
              current.match.currentQuestionIndex + 1,
            );
      }
    }
  }
}

final battleProvider = AsyncNotifierProvider<BattleNotifier, BattleState>(
  BattleNotifier.new,
);
