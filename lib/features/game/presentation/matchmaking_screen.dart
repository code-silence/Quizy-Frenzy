import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/game_repository.dart';
import '../providers/game_provider.dart';
import 'battle_screen.dart';
import '../../../main.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _roomCode;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _randomMatch() async {
    setState(() => _loading = true);
    try {
      final match = await ref
          .read(gameRepositoryProvider)
          .joinOrCreateRandom();

      if (!mounted) return;
      await ref.read(battleProvider.notifier).initBattle(match);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BattleScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createRoomCode() async {
    setState(() => _loading = true);
    try {
      final match = await ref
          .read(gameRepositoryProvider)
          .createMatch(useRoomCode: true);

      setState(() => _roomCode = match.roomCode);

      await ref.read(battleProvider.notifier).initBattle(match);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BattleScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinByCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 6-character code')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final match = await ref
          .read(gameRepositoryProvider)
          .joinByRoomCode(code);

      if (match == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Room not found or already started'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      await ref.read(battleProvider.notifier).initBattle(match);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BattleScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Battle Mode')),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up battle...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.sports_kabaddi_rounded,
                            size: 72, color: scheme.primary),
                        const SizedBox(height: 8),
                        Text('1v1 Battle',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Challenge a player to a quiz battle',
                            style:
                                TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Random matchmaking
                  _SectionLabel(label: 'Quick Match'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _randomMatch,
                      icon: const Icon(Icons.shuffle_rounded),
                      label: const Text('Find Random Opponent',
                          style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Create room code
                  _SectionLabel(label: 'Play with a Friend'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.tonal(
                      onPressed: _createRoomCode,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded),
                          SizedBox(width: 8),
                          Text('Create Room',
                              style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Join by code
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Room Code',
                            hintText: 'ABCD12',
                            counterText: '',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: scheme.surfaceContainerHighest
                                .withOpacity(0.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: _joinByCode,
                          child: const Text('Join'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5));
  }
}