import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../../quiz/presentation/widgets/option_tile.dart';
import '../../quiz/presentation/widgets/quiz_timer.dart';
import 'battle_result_screen.dart';

class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battleAsync = ref.watch(battleProvider);
    final scheme = Theme.of(context).colorScheme;

    return battleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (battle) {
        // Navigate to result when finished
        if (battle.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (_) => const BattleResultScreen()),
            );
          });
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // Waiting for opponent
        if (!battle.bothPlayersJoined || battle.match.isWaiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Waiting...')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text('Waiting for opponent...',
                      style: TextStyle(fontSize: 18)),
                  if (battle.match.roomCode != null) ...[
                    const SizedBox(height: 24),
                    Text('Room Code',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        battle.match.roomCode!,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Share this code with your friend',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13)),
                  ],
                ],
              ),
            ),
          );
        }

        final question = battle.currentQuestion;
        final myPlayer = battle.myPlayer;
        final opponent = battle.opponent;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Player vs Player scores
                  Row(
                    children: [
                      _PlayerChip(
                        name: myPlayer?.username ?? 'You',
                        score: myPlayer?.score ?? 0,
                        isMe: true,
                        color: scheme.primary,
                      ),
                      const Spacer(),
                      Icon(Icons.flash_on_rounded,
                          color: scheme.primary, size: 20),
                      const Spacer(),
                      _PlayerChip(
                        name: opponent?.username ?? 'Opponent',
                        score: opponent?.score ?? 0,
                        isMe: false,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Question progress
                  Row(
                    children: [
                      Text(
                        '${battle.match.currentQuestionIndex + 1}/${battle.questions.length}',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (battle.match.currentQuestionIndex + 1) /
                                battle.questions.length,
                            minHeight: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Timer
                  QuizTimer(
                    secondsLeft: battle.secondsLeft,
                    totalSeconds: BattleNotifier.questionTimeSeconds,
                  ),
                  const SizedBox(height: 24),

                  // Question
                  Text(
                    question.questionText,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                            fontWeight: FontWeight.w600, height: 1.4),
                  ),
                  const SizedBox(height: 28),

                  // Options
                  for (final label in ['A', 'B', 'C', 'D'])
                    OptionTile(
                      label: label,
                      text: question.optionText(label),
                      answered: battle.answered,
                      isSelected: battle.selectedAnswer == label,
                      isCorrect: question.correctAnswer == label,
                      onTap: () => ref
                          .read(battleProvider.notifier)
                          .selectAnswer(label),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final String name;
  final int score;
  final bool isMe;
  final Color color;

  const _PlayerChip({
    required this.name,
    required this.score,
    required this.isMe,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 4),
        Text(isMe ? 'You' : name,
            style: const TextStyle(fontSize: 12)),
        Text('$score pts',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}