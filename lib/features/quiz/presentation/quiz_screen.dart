import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_provider.dart';
//import '../models/quiz_result_model.dart';
import 'widgets/option_tile.dart';
import 'widgets/quiz_timer.dart';
import 'result_screen.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(quizProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: quizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (quiz) {
          // Show result screen when finished
          // WITH this:
          if (quiz.finished) {
            final result = ref.read(quizProvider.notifier).getResult();
            // Push as proper route so ResultScreen has clean provider scope
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
              );
            });
            // Show loading while navigating
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final question = quiz.currentQuestion;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar — progress + timer
                  Row(
                    children: [
                      Text(
                        '${quiz.currentIndex + 1}/${quiz.totalQuestions}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value:
                                (quiz.currentIndex + 1) / quiz.totalQuestions,
                            minHeight: 8,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Timer
                  QuizTimer(
                    secondsLeft: quiz.secondsLeft,
                    totalSeconds: QuizNotifier.questionTimeSeconds,
                  ),
                  const SizedBox(height: 28),

                  // Category chip
                  Chip(
                    label: Text(
                      question.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    backgroundColor: scheme.primaryContainer,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),

                  // Question text
                  Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Options
                  for (final label in ['A', 'B', 'C', 'D'])
                    OptionTile(
                      label: label,
                      text: question.optionText(label),
                      answered: quiz.answered,
                      isSelected: quiz.selectedAnswer == label,
                      isCorrect: question.correctAnswer == label,
                      onTap:
                          () => ref
                              .read(quizProvider.notifier)
                              .selectAnswer(label),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
