import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  final String label;      // 'A' | 'B' | 'C' | 'D'
  final String text;
  final bool answered;
  final bool isSelected;
  final bool isCorrect;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.label,
    required this.text,
    required this.answered,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color bgColor = scheme.surfaceContainerHighest.withOpacity(0.4);
    Color borderColor = Colors.transparent;
    Color labelColor = scheme.primary;

    if (answered) {
      if (isCorrect) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        labelColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        labelColor = Colors.red;
      }
    }

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            // Option label bubble
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            if (answered && isCorrect)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 20),
            if (answered && isSelected && !isCorrect)
              const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }
}