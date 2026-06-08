import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match_model.dart';

class GameRepository {
  final SupabaseClient _client;
  const GameRepository(this._client);

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<List<String>> _fetchQuestionIds(int count) async {
    final data = await _client.from('questions').select('id').limit(count);
    final list = (data as List).map((e) => e['id'] as String).toList();
    list.shuffle();
    return list;
  }

  Future<MatchModel> createMatch({bool useRoomCode = false}) async {
    final questionIds = await _fetchQuestionIds(5);
    final Map<String, dynamic> payload = {
      'status': 'waiting',
      'question_ids': questionIds,
      'current_question_index': 0,
    };
    if (useRoomCode) {
      payload['room_code'] = _generateRoomCode();
    }

    final data =
        await _client.from('matches').insert(payload).select().single();
    final match = MatchModel.fromMap(data);

    await _client.from('match_players').insert({
      'match_id': match.id,
      'player_id': _client.auth.currentUser!.id,
      'is_host': true,
      'ready': true,
    });

    return match;
  }

  Future<MatchModel?> joinByRoomCode(String code) async {
    final currentUserId = _client.auth.currentUser!.id;

    final data = await _client
        .from('matches')
        .select()
        .eq('room_code', code.toUpperCase())
        .eq('status', 'waiting')
        .maybeSingle();

    if (data == null) return null;
    final match = MatchModel.fromMap(data);

    final existing = await _client
        .from('match_players')
        .select()
        .eq('match_id', match.id)
        .eq('player_id', currentUserId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('match_players').insert({
        'match_id': match.id,
        'player_id': currentUserId,
        'is_host': false,
        'ready': true,
      });
    }

    return match;
  }

  Future<MatchModel> joinOrCreateRandom() async {
    final currentUserId = _client.auth.currentUser!.id;

    final data = await _client
        .from('matches')
        .select()
        .eq('status', 'waiting')
        .isFilter('room_code', null)
        .limit(1)
        .maybeSingle();

    if (data != null) {
      final match = MatchModel.fromMap(data);

      final existing = await _client
          .from('match_players')
          .select()
          .eq('match_id', match.id)
          .eq('player_id', currentUserId)
          .maybeSingle();

      if (existing == null) {
        await _client.from('match_players').insert({
          'match_id': match.id,
          'player_id': currentUserId,
          'is_host': false,
          'ready': true,
        });
      }

      return match;
    }

    return createMatch(useRoomCode: false);
  }

  Future<void> startMatch(String matchId) async {
    await _client
        .from('matches')
        .update({
          'status': 'in_progress',
          'started_at': DateTime.now().toIso8601String(),
        })
        .eq('id', matchId);
  }

  Future<void> submitAnswer({
    required String matchId,
    required String playerId,
    required List<String?> answers,
    required int score,
  }) async {
    await _client
        .from('match_players')
        .update({'answers': answers, 'score': score})
        .eq('match_id', matchId)
        .eq('player_id', playerId);
  }

  Future<void> nextQuestion(String matchId, int nextIndex) async {
    await _client
        .from('matches')
        .update({'current_question_index': nextIndex})
        .eq('id', matchId);
  }

  Future<void> finishMatch(String matchId) async {
    await _client
        .from('matches')
        .update({
          'status': 'finished',
          'finished_at': DateTime.now().toIso8601String(),
        })
        .eq('id', matchId);
  }

  Future<List<MatchPlayerModel>> fetchPlayers(String matchId) async {
    final rows = await _client
        .from('match_players')
        .select()
        .eq('match_id', matchId);

    final players = <MatchPlayerModel>[];
    for (final row in rows) {
      try {
        final profile = await _client
            .from('profiles')
            .select('username')
            .eq('id', row['player_id'] as String)
            .single();
        print('=== fetchPlayers profile: $profile ===');
        players.add(MatchPlayerModel.fromMap({
          ...row,
          'profiles': {'username': profile['username']},
        }));
      } catch (e) {
        print('=== fetchPlayers FAILED: $e ===');
        players.add(MatchPlayerModel.fromMap({
          ...row,
          'profiles': {'username': 'Player'},
        }));
      }
    }
    return players;
  }

  Stream<MatchModel> watchMatch(String matchId) {
    return _client
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('id', matchId)
        .map((rows) => MatchModel.fromMap(rows.first));
  }

  Stream<List<MatchPlayerModel>> watchPlayers(String matchId) {
    return _client
        .from('match_players')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .asyncMap((rows) async {
          print('=== watchPlayers fired: ${rows.length} rows ===');
          final players = <MatchPlayerModel>[];
          for (final row in rows) {
            print('=== row player_id: ${row['player_id']} ===');
            try {
              final profile = await _client
                  .from('profiles')
                  .select('username')
                  .eq('id', row['player_id'] as String)
                  .single();

              print('=== profile result: $profile ===');
              print('=== username value: ${profile['username']} ===');

              players.add(MatchPlayerModel.fromMap({
                ...row,
                'profiles': {'username': profile['username']},
              }));
            } catch (e) {
              print('=== profile fetch FAILED: $e ===');
              await Future.delayed(const Duration(milliseconds: 500));
              try {
                final profile = await _client
                    .from('profiles')
                    .select('username')
                    .eq('id', row['player_id'] as String)
                    .single();
                print('=== retry profile result: $profile ===');
                players.add(MatchPlayerModel.fromMap({
                  ...row,
                  'profiles': {'username': profile['username']},
                }));
              } catch (e2) {
                print('=== retry FAILED: $e2 ===');
                players.add(MatchPlayerModel.fromMap({
                  ...row,
                  'profiles': {'username': 'Player'},
                }));
              }
            }
          }
          print('=== final players list: ${players.map((p) => p.username).toList()} ===');
          return players;
        });
  }
}