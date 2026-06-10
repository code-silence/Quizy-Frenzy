import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/character_repository.dart';
import '../models/character_model.dart';
import '../../../main.dart';

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return CharacterRepository(supabase);
});

final charactersProvider = FutureProvider<List<CharacterModel>>((ref) async {
  return ref.read(characterRepositoryProvider).fetchAllCharacters();
});