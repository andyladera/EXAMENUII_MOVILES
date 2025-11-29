class AMCLclsDashboardMetrics {
  final int totalSurveys;
  final int activeSurveys;
  final int totalResponses;
  final int totalUsers;
  final int surveyors;
  final Map<String, int> responsesBySurvey; // surveyId -> count
  final Map<String, String> surveyTitles; // surveyId -> title
  final List<Map<String, dynamic>> recentResponses;
  final List<Map<String, dynamic>> responsesOverTime; // Por día
  
  AMCLclsDashboardMetrics({
    required this.totalSurveys,
    required this.activeSurveys,
    required this.totalResponses,
    required this.totalUsers,
    required this.surveyors,
    required this.responsesBySurvey,
    required this.surveyTitles,
    required this.recentResponses,
    required this.responsesOverTime,
  });
}

class AMCLclsLocationData {
  final String surveyTitle;
  final String respondentName;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime completedAt;
  
  AMCLclsLocationData({
    required this.surveyTitle,
    required this.respondentName,
    this.latitude,
    this.longitude,
    this.address,
    required this.completedAt,
  });
}
