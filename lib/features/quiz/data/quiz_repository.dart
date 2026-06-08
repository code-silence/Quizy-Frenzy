import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';

class QuizRepository {
  final SupabaseClient _client;
  const QuizRepository(this._client);

  // Fetch random questions — optional category + difficulty filter
  Future<List<QuestionModel>> fetchQuestions({
    int limit = 5,
    String? category,
    String? difficulty,
  }) async {
    var query = _client.from('questions').select();

    if (category != null) query = query.eq('category', category);
    if (difficulty != null) query = query.eq('difficulty', difficulty);

    final data = await query.limit(limit);

    final questions = (data as List)
        .map((e) => QuestionModel.fromMap(e))
        .toList();

    questions.shuffle(); // randomize order
    return questions;
  }
}