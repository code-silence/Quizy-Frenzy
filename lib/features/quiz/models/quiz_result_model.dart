class QuizResultModel {
  final int totalQuestions;
  final int correctAnswers;
  final int timeTakenSeconds;
  final int xpEarned;
  final int coinsEarned;

  const QuizResultModel({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeTakenSeconds,
    required this.xpEarned,
    required this.coinsEarned,
  });

  double get accuracy => correctAnswers / totalQuestions;
  int get wrongAnswers => totalQuestions - correctAnswers;

  // XP formula: 10 per correct + accuracy bonus
  static int calculateXp(int correct, int total) {
    final base = correct * 10;
    final bonus = correct == total ? 20 : 0; // perfect score bonus
    return base + bonus;
  }

  // Coins formula: 5 per correct
  static int calculateCoins(int correct) => correct * 5;
}