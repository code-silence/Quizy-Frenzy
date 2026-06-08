import 'package:flutter/material.dart';

class QuizTimer extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;

  const QuizTimer({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = secondsLeft / totalSeconds;
    final color = secondsLeft <= 5
        ? Colors.red
        : secondsLeft <= 10
            ? Colors.orange
            : scheme.primary;

    return Column(
      children: [
        Text(
          '$secondsLeft',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}