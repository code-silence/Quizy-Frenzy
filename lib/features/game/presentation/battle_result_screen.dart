import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../../profile/providers/profile_provider.dart';

class BattleResultScreen extends ConsumerStatefulWidget {
  const BattleResultScreen({super.key});

  @override
  ConsumerState<BattleResultScreen> createState() =>
      _BattleResultScreenState();
}

class _BattleResultScreenState extends ConsumerState<BattleResultScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveRewards();
  }

  Future<void> _saveRewards() async {
    final battle = ref.read(battleProvider).value;
    if (battle == null) return;

    final myPlayer = battle.myPlayer;
    if (myPlayer == null) return;

    // XP: 10 per correct answer + 30 bonus for winning
    final opponent = battle.opponent;
    final won = opponent != null && myPlayer.score > opponent.score;
    final xp = (myPlayer.score * 10) + (won ? 30 : 0);
    final coins = (myPlayer.score * 5) + (won ? 15 : 0);

    await ref
        .read(profileProvider.notifier)
        .addXpAndCoins(xp: xp, coins: coins);

    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final battle = ref.watch(battleProvider).value;
    final scheme = Theme.of(context).colorScheme;

    if (battle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final myPlayer = battle.myPlayer;
    final opponent = battle.opponent;
    final myScore = myPlayer?.score ?? 0;
    final opponentScore = opponent?.score ?? 0;
    final won = myScore > opponentScore;
    final draw = myScore == opponentScore;

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
                  won
                      ? Icons.emoji_events_rounded
                      : draw
                          ? Icons.handshake_rounded
                          : Icons.sentiment_dissatisfied_rounded,
                  size: 88,
                  color: won
                      ? Colors.amber
                      : draw
                          ? scheme.primary
                          : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  won ? 'You Won!' : draw ? 'Draw!' : 'You Lost!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // Score comparison
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ScoreBox(
                      name: 'You',
                      score: myScore,
                      highlight: won || draw,
                      color: scheme.primary,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('vs',
                          style: TextStyle(
                              fontSize: 18,
                              color: scheme.onSurfaceVariant)),
                    ),
                    _ScoreBox(
                      name: opponent?.username ?? 'Opponent',
                      score: opponentScore,
                      highlight: !won && !draw,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Rewards
                if (_saved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: scheme.onPrimaryContainer),
                        const SizedBox(width: 6),
                        Text(
                          '+${(myScore * 10) + (won ? 30 : 0)} XP  •  +${(myScore * 5) + (won ? 15 : 0)} Coins',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),

                // Back to home
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    child: const Text('Back to Home',
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

class _ScoreBox extends StatelessWidget {
  final String name;
  final int score;
  final bool highlight;
  final Color color;

  const _ScoreBox({
    required this.name,
    required this.score,
    required this.highlight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: highlight
                ? color.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: highlight ? color : Colors.grey.shade300,
                width: 2),
          ),
          child: Text(
            '$score',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: highlight ? color : Colors.grey),
          ),
        ),
      ],
    );
  }
}