import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character_model.dart';

class CharacterRepository {
  final SupabaseClient _client;
  const CharacterRepository(this._client);

  Future<List<CharacterModel>> fetchAllCharacters() async {
    final data = await _client
        .from('characters')
        .select()
        .order('unlock_level', ascending: true);
    return (data as List).map((e) => CharacterModel.fromMap(e)).toList();
  }
}