import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/quiz_repository.dart';
import '../models/question_model.dart';
import '../models/quiz_result_model.dart';
import '../../../main.dart';

// Repository
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(supabase);
});

// Quiz session state
class QuizState {
  final List<QuestionModel> questions;
  final int currentIndex;
  final String? selectedAnswer;   // what user picked this round
  final bool answered;            // locked in?
  final List<String?> userAnswers; // full answer history
  final bool finished;
  final int secondsLeft;

  const QuizState({
    required this.questions,
    required this.currentIndex,
    required this.selectedAnswer,
    required this.answered,
    required this.userAnswers,
    required this.finished,
    required this.secondsLeft,
  });

  QuestionModel get currentQuestion => questions[currentIndex];
  bool get isLastQuestion => currentIndex == questions.length - 1;
  int get totalQuestions => questions.length;

  QuizState copyWith({
    int? currentIndex,
    String? selectedAnswer,
    bool? answered,
    List<String?>? userAnswers,
    bool? finished,
    int? secondsLeft,
    bool clearSelected = false,
  }) {
    return QuizState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswer: clearSelected ? null : selectedAnswer ?? this.selectedAnswer,
      answered: answered ?? this.answered,
      userAnswers: userAnswers ?? this.userAnswers,
      finished: finished ?? this.finished,
      secondsLeft: secondsLeft ?? this.secondsLeft,
    );
  }
}

// Quiz notifier
class QuizNotifier extends AsyncNotifier<QuizState> {
  Timer? _timer;
  static const int questionTimeSeconds = 15;

  @override
  Future<QuizState> build() async {
    ref.onDispose(() => _timer?.cancel());
    final questions = await ref
        .read(quizRepositoryProvider)
        .fetchQuestions(limit: 5);

    final initialState = QuizState(
      questions: questions,
      currentIndex: 0,
      selectedAnswer: null,
      answered: false,
      userAnswers: List.filled(questions.length, null),
      finished: false,
      secondsLeft: questionTimeSeconds,
    );

    _startTimer();
    return initialState;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final current = state.value;
      if (current == null) return;

      if (current.secondsLeft <= 1) {
        t.cancel();
        // Time's up — auto move
        _timeUp();
      } else {
        state = AsyncData(
            current.copyWith(secondsLeft: current.secondsLeft - 1));
      }
    });
  }

  void _timeUp() {
    final current = state.value;
    if (current == null || current.answered) return;
    // Mark as answered with no selection (null = timed out)
    final updatedAnswers = List<String?>.from(current.userAnswers);
    updatedAnswers[current.currentIndex] = null;
    state = AsyncData(current.copyWith(answered: true, userAnswers: updatedAnswers));
    // Move after short delay
    Future.delayed(const Duration(seconds: 1), _next);
  }

  void selectAnswer(String answer) {
    final current = state.value;
    if (current == null || current.answered) return;
    _timer?.cancel();

    final updatedAnswers = List<String?>.from(current.userAnswers);
    updatedAnswers[current.currentIndex] = answer;

    state = AsyncData(current.copyWith(
      selectedAnswer: answer,
      answered: true,
      userAnswers: updatedAnswers,
    ));

    // Auto-advance after showing result
    Future.delayed(const Duration(seconds: 1, milliseconds: 500), _next);
  }

  void _next() {
    final current = state.value;
    if (current == null) return;

    if (current.isLastQuestion) {
      state = AsyncData(current.copyWith(finished: true));
      return;
    }

    state = AsyncData(current.copyWith(
      currentIndex: current.currentIndex + 1,
      answered: false,
      secondsLeft: questionTimeSeconds,
      clearSelected: true,
    ));

    _startTimer();
  }

  // Calculate final result
  QuizResultModel getResult() {
    final current = state.value!;
    int correct = 0;
    for (int i = 0; i < current.questions.length; i++) {
      if (current.userAnswers[i] == current.questions[i].correctAnswer) {
        correct++;
      }
    }
    return QuizResultModel(
      totalQuestions: current.totalQuestions,
      correctAnswers: correct,
      timeTakenSeconds: 0,
      xpEarned: QuizResultModel.calculateXp(correct, current.totalQuestions),
      coinsEarned: QuizResultModel.calculateCoins(correct),
    );
  }

  // Restart quiz
  Future<void> restart() async {
    _timer?.cancel();
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}

final quizProvider =
    AsyncNotifierProvider<QuizNotifier, QuizState>(QuizNotifier.new);