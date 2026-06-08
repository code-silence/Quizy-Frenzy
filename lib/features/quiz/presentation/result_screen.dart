import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_result_model.dart';
import '../providers/quiz_provider.dart';
import '../../profile/providers/profile_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final QuizResultModel result;
  const ResultScreen({super.key, required this.result});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _saved = false;
  bool _saving = true;

  @override
  void initState() {
    super.initState();
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    try {
      await ref.read(profileProvider.notifier).addXpAndCoins(
            xp: widget.result.xpEarned,
            coins: widget.result.coinsEarned,
          );
    } finally {
      if (mounted) {
        setState(() {
          _saved = true;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = widget.result;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Result icon
                Icon(
                  result.accuracy == 1.0
                      ? Icons.emoji_events_rounded
                      : result.accuracy >= 0.5
                          ? Icons.thumb_up_rounded
                          : Icons.sentiment_dissatisfied_rounded,
                  size: 88,
                  color: result.accuracy == 1.0
                      ? Colors.amber
                      : result.accuracy >= 0.5
                          ? Colors.green
                          : Colors.red,
                ),
                const SizedBox(height: 16),

                Text(
                  result.accuracy == 1.0
                      ? 'Perfect Score!'
                      : result.accuracy >= 0.5
                          ? 'Good Job!'
                          : 'Keep Practicing!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Text(
                  '${result.correctAnswers} / ${result.totalQuestions} correct',
                  style: TextStyle(
                      fontSize: 16, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),

                // Accuracy %
                Text(
                  '${(result.accuracy * 100).toStringAsFixed(0)}% accuracy',
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Rewards row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RewardChip(
                      icon: Icons.bolt_rounded,
                      label: '+${result.xpEarned} XP',
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _RewardChip(
                      icon: Icons.monetization_on_rounded,
                      label: '+${result.coinsEarned} Coins',
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Save status
                _saving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Saving progress...',
                              style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 13)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _saved
                                ? 'Progress saved!'
                                : 'Could not save progress',
                            style: TextStyle(
                              color: _saved ? Colors.green : Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 40),

                // Level up notice (if applicable)
                Consumer(builder: (context, ref, _) {
                  final profile = ref.watch(profileProvider).value;
                  if (profile == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.military_tech_rounded,
                            color: scheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Level ${profile.level}  •  ${profile.xp} XP  •  ${profile.coins} Coins',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 40),

                // Play again
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.read(quizProvider.notifier).restart(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Play Again',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),

                // Back to profile
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Profile',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RewardChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: color, fontSize: 15)),
        ],
      ),
    );
  }
}