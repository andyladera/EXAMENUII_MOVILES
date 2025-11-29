class AMCLclsSurveyStats {
  final int totalResponses;
  final int totalQuestions;
  final Map<String, dynamic> questionStats; // questionId -> stats
  final List<Map<String, dynamic>> responsesByDate;
  final double averageCompletionTime; // en minutos
  
  AMCLclsSurveyStats({
    required this.totalResponses,
    required this.totalQuestions,
    required this.questionStats,
    required this.responsesByDate,
    required this.averageCompletionTime,
  });
}

class AMCLclsQuestionStats {
  final String questionId;
  final String questionText;
  final String questionType;
  final int totalAnswers;
  final Map<String, int>? optionCounts; // Para multiple choice
  final double? averageRating; // Para rating
  final List<String>? openEndedAnswers; // Para open ended
  
  AMCLclsQuestionStats({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.totalAnswers,
    this.optionCounts,
    this.averageRating,
    this.openEndedAnswers,
  });
}
