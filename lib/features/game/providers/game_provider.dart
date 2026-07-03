import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/game_repository.dart';
import '../models/match_model.dart';
import '../../quiz/models/question_model.dart';
import '../../quiz/providers/quiz_provider.dart';
import '../../ability/models/ability_state.dart';
import '../../ability/providers/ability_provider.dart';
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
  final List<bool> eliminatedOptions;

  const BattleState({
    required this.match,
    required this.players,
    required this.questions,
    required this.selectedAnswer,
    required this.answered,
    required this.secondsLeft,
    required this.finished,
    required this.eliminatedOptions,
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
    List<bool>? eliminatedOptions,
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
      eliminatedOptions: eliminatedOptions ?? this.eliminatedOptions,
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

    // Use microtask so ability init happens AFTER build completes
    Future.microtask(() => ref.read(abilityProvider.notifier).initForBattle());

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
        eliminatedOptions: [false, false, false, false],
      ),
    );

    // If the match is already in progress when we initialize, start the timer
    // so non-hosts also begin counting down.
    if (match.isInProgress) {
      _startTimer();
    }

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

      // Question advanced (start timer for both players)
      if (updatedMatch.currentQuestionIndex !=
          current.match.currentQuestionIndex) {
        _timer?.cancel();
        state = AsyncData(
          current.copyWith(
            match: updatedMatch,
            answered: false,
            secondsLeft: questionTimeSeconds,
            clearSelected: true,
            eliminatedOptions: [false, false, false, false],
          ),
        );
        _startTimer(); // BOTH players start timer on question change
      } else {
        state = AsyncData(current.copyWith(match: updatedMatch));
      }

      // Start timer when match goes in_progress (both players)
      if (updatedMatch.isInProgress && !current.match.isInProgress) {
        _startTimer();
      }
    });
  }

  void _listenToPlayers(String matchId) {
    _playersSub = ref
        .read(gameRepositoryProvider)
        .watchPlayers(matchId)
        .listen(
          (players) async {
            print('=== players update received: ${players.length} players ===');
            for (final p in players) {
              print('  player: ${p.username} | host: ${p.isHost}');
            }

            final current = state.value;
            if (current == null) return;
            state = AsyncData(current.copyWith(players: players));

            // Detect Luna sabotage — if MY player row has sabotaged=true
            final uid = supabase.auth.currentUser?.id;
            final myRow = players.where((p) => p.playerId == uid).firstOrNull;
            if (myRow != null && myRow.sabotaged && !current.answered) {
              // Reduce my timer by 3 seconds
              final newSeconds = (current.secondsLeft - 3).clamp(1, 999);
              state = AsyncData(current.copyWith(secondsLeft: newSeconds));

              // Clear the sabotage flag so it doesn't keep triggering
              await ref
                  .read(gameRepositoryProvider)
                  .clearSabotage(matchId: matchId, playerId: uid!);
            }

            print(
              '=== isWaiting: ${current.match.isWaiting} | isHost: ${current.isHost} ===',
            );

            if (players.length >= 2 &&
                current.match.isWaiting &&
                current.isHost) {
              print('=== AUTO STARTING MATCH ===');
              await ref.read(gameRepositoryProvider).startMatch(matchId);
              // Host starts the timer immediately after starting the match
              _startTimer();
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
    if (current == null) return;

    if (!current.answered) {
      _submitAnswer(
        null,
      ); // submits null answer which calls _waitForBothAnswers
    } else if (current.isHost) {
      // Host already answered but timer ran out — force advance
      _waitForBothAnswers(current);
    }
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

    // Host advances ONLY after both players answered OR timer ends
    if (current.isHost) {
      _waitForBothAnswers(current);
    }
  }

  Future<void> _waitForBothAnswers(BattleState current) async {
    final matchId = current.match.id;
    final totalQuestions = current.questions.length;
    final currentIndex = current.match.currentQuestionIndex;

    // Poll every 500ms until opponent answers or timer runs out
    for (int i = 0; i < 30; i++) {
      // max 15 seconds (30 × 500ms)
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch latest player states
      final players = await ref
          .read(gameRepositoryProvider)
          .fetchPlayers(matchId);

      final bothAnswered = players.every(
        (p) => p.answers.length > currentIndex,
      );

      final currentState = state.value;
      if (currentState == null) return;

      // Also stop waiting if timer already ran out
      if (bothAnswered || currentState.secondsLeft <= 0) {
        await Future.delayed(const Duration(milliseconds: 500));

        final isLast = currentIndex >= totalQuestions - 1;
        if (isLast) {
          await ref.read(gameRepositoryProvider).finishMatch(matchId);
        } else {
          await ref
              .read(gameRepositoryProvider)
              .nextQuestion(matchId, currentIndex + 1);
        }
        return;
      }
    }

    // Timeout fallback — advance anyway after 15 seconds
    final currentState = state.value;
    if (currentState == null) return;
    final isLast = currentIndex >= totalQuestions - 1;
    if (isLast) {
      await ref.read(gameRepositoryProvider).finishMatch(matchId);
    } else {
      await ref
          .read(gameRepositoryProvider)
          .nextQuestion(matchId, currentIndex + 1);
    }
  }

  Future<void> useAbility() async {
    final current = state.value;
    if (current == null) return;

    final ability = ref.read(abilityProvider);
    if (!ability.canUse) return;

    switch (ability.type) {
      case AbilityType.hint:
        _eliminateWrongOptions(current, count: 1);
        break;
      case AbilityType.doubleHint:
        _eliminateWrongOptions(current, count: 2);
        break;
      case AbilityType.extraTime:
        state = AsyncData(
          current.copyWith(secondsLeft: current.secondsLeft + 5),
        );
        break;
      case AbilityType.retry:
        if (current.answered &&
            current.selectedAnswer != current.currentQuestion.correctAnswer) {
          state = AsyncData(
            current.copyWith(
              answered: false,
              secondsLeft: 10,
              clearSelected: true,
              eliminatedOptions: [false, false, false, false],
            ),
          );
          _startTimer();
        } else {
          return;
        }
        break;
      case AbilityType.sabotage:
        await ref
            .read(gameRepositoryProvider)
            .sabotageOpponent(
              matchId: current.match.id,
              opponentId: current.opponent?.playerId ?? '',
            );
        break;
      case AbilityType.none:
        return;
    }

    ref.read(abilityProvider.notifier).markUsed();

    // Track usage in Supabase
    final myPlayer = current.myPlayer;
    if (myPlayer != null) {
      await ref
          .read(gameRepositoryProvider)
          .markAbilityUsed(
            matchId: current.match.id,
            playerId: myPlayer.playerId,
          );
    }
  }

  void _eliminateWrongOptions(BattleState current, {required int count}) {
    final correct = current.currentQuestion.correctAnswer;
    final options = ['A', 'B', 'C', 'D'];
    final wrong = options.where((o) => o != correct).toList()..shuffle();

    final eliminated = List<bool>.from(current.eliminatedOptions);
    int eliminatedCount = 0;

    for (final option in wrong) {
      if (eliminatedCount >= count) break;
      final index = options.indexOf(option);
      if (!eliminated[index]) {
        eliminated[index] = true;
        eliminatedCount++;
      }
    }

    state = AsyncData(current.copyWith(eliminatedOptions: eliminated));
  }
}

final battleProvider = AsyncNotifierProvider<BattleNotifier, BattleState>(
  BattleNotifier.new,
);
