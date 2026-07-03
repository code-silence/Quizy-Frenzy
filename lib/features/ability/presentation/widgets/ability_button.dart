import 'package:flutter/material.dart';
import '../../models/ability_state.dart';

class AbilityButton extends StatelessWidget {
  final AbilityState ability;
  final VoidCallback onTap;

  const AbilityButton({
    super.key,
    required this.ability,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (ability.type == AbilityType.none || !ability.available) {
      return const SizedBox.shrink();
    }

    final canUse = ability.canUse;
    final label = AbilityState.abilityLabel(ability.type);
    final icon = AbilityState.abilityIcon(ability.type);

    return GestureDetector(
      onTap: canUse ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: canUse
              ? const LinearGradient(
                  colors: [Color(0xFFFFB347), Color(0xFFFF6B35)],
                )
              : null,
          color: canUse ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(30),
          boxShadow: canUse
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB347).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              ability.used ? 'Used' : label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: canUse ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}