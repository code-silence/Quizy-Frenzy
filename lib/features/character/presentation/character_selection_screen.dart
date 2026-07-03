import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character_model.dart';
import '../providers/character_provider.dart';
import '../../profile/providers/profile_provider.dart';

class CharacterSelectionScreen extends ConsumerStatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  ConsumerState<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState
    extends ConsumerState<CharacterSelectionScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set initial index to currently selected character
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final characters = ref.read(charactersProvider).value;
      final profile = ref.read(profileProvider).value;
      if (characters != null && profile != null) {
        final index = characters.indexWhere(
          (c) => c.characterKey == profile.selectedCharacter,
        );
        if (index != -1 && index != _selectedIndex) {
          setState(() => _selectedIndex = index);
        }
      }
    });

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _selectCharacter(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _slideController.reset();
    _fadeController.reset();
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(charactersProvider);
    final profile = ref.read(profileProvider).value;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: charactersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (characters) {
          final selected = characters[_selectedIndex];
          final isUnlocked =
              profile != null && profile.level >= selected.unlockLevel;
          final isSelected =
              profile?.selectedCharacter == selected.characterKey;

          final gradientColors = [
            Color(selected.colors[0]),
            Color(selected.colors[1]),
          ];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // App bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Choose Character',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: Row(
                      children: [
                        // LEFT — character full image
                        Expanded(
                          flex: 5,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Glow circle behind character
                                  Container(
                                    width: size.width * 0.45,
                                    height: size.width * 0.45,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  // Character image
                                  RepaintBoundary(
                                    child: Image.asset(
                                      selected.fullImagePath,
                                      key: ValueKey(selected.characterKey),
                                      height: size.height * 0.55,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (_, __, ___) => _PlaceholderCharacter(
                                            name: selected.name,
                                            color: Color(selected.colors[0]),
                                          ),
                                    ),
                                  ),
                                  // Lock overlay
                                  if (!isUnlocked)
                                    Container(
                                      width: size.width * 0.45,
                                      height: size.height * 0.55,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lock_rounded,
                                            color: Colors.white,
                                            size: 48,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // RIGHT — character info
                        Expanded(
                          flex: 5,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 20,
                                top: 16,
                                bottom: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Character icon
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white.withOpacity(0.15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.asset(
                                        selected.iconImagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Icon(
                                              Icons.person_rounded,
                                              color: Colors.white,
                                              size: 36,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Name
                                  Text(
                                    selected.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),

                                  // Gender tag
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      selected.gender.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Ability card
                                  if (selected.hasAbility) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.auto_awesome_rounded,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                selected.abilityName!,
                                                style: const TextStyle(
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            selected.abilityDescription!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.replay_rounded,
                                                color: Colors.white70,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${selected.abilityUses}x per match',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.shield_rounded,
                                            color: Colors.white54,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'No special ability',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),

                                  // Unlock level badge
                                  if (!selected.isFree)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isUnlocked
                                                ? Colors.green.withOpacity(0.3)
                                                : Colors.red.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              isUnlocked
                                                  ? Colors.green
                                                  : Colors.red.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isUnlocked
                                                ? Icons.lock_open_rounded
                                                : Icons.lock_rounded,
                                            color: Colors.white,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isUnlocked
                                                ? 'Unlocked'
                                                : 'Unlock at Level ${selected.unlockLevel}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 20),

                                  // Select button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child:
                                        isSelected
                                            ? FilledButton.icon(
                                              onPressed: null,
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.3),
                                              ),
                                              icon: const Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.white,
                                              ),
                                              label: const Text(
                                                'Selected',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                            : FilledButton(
                                              onPressed:
                                                  isUnlocked
                                                      ? () async {
                                                        await ref
                                                            .read(
                                                              profileProvider
                                                                  .notifier,
                                                            )
                                                            .updateCharacter(
                                                              selected
                                                                  .characterKey,
                                                            );
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '${selected.name} selected!',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.green,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                      : null,
                                              style: FilledButton.styleFrom(
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.25),
                                                disabledBackgroundColor: Colors
                                                    .white
                                                    .withOpacity(0.1),
                                              ),
                                              child: Text(
                                                isUnlocked
                                                    ? 'Select ${selected.name}'
                                                    : 'Level ${selected.unlockLevel} Required',
                                                style: TextStyle(
                                                  color:
                                                      isUnlocked
                                                          ? Colors.white
                                                          : Colors.white54,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom character selector row
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount: characters.length,
                      itemBuilder: (context, index) {
                        final char = characters[index];
                        final unlocked =
                            profile != null &&
                            profile.level >= char.unlockLevel;
                        final isActive = index == _selectedIndex;

                        return GestureDetector(
                          onTap: () => _selectCharacter(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 12),
                            width: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    isActive
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                width: isActive ? 2.5 : 1,
                              ),
                              color:
                                  isActive
                                      ? Colors.white.withOpacity(0.25)
                                      : Colors.white.withOpacity(0.1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    char.iconImagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Center(
                                          child: Text(
                                            char.name[0],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                  ),
                                  if (!unlocked)
                                    Container(
                                      color: Colors.black.withOpacity(0.5),
                                      child: const Icon(
                                        Icons.lock_rounded,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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

// Placeholder when image asset is missing
class _PlaceholderCharacter extends StatelessWidget {
  final String name;
  final Color color;
  const _PlaceholderCharacter({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 300,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_rounded, color: Colors.white, size: 80),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
