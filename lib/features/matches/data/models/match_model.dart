class MatchModel {
  final int id;
  final String utcDate;
  final String status;
  final int matchday;
  final String stage;
  final String? group;
  final String homeTeamName;
  final String? homeTeamCrest;
  final String awayTeamName;
  final String? awayTeamCrest;
  final int? homeScore;
  final int? awayScore;

  MatchModel({
    required this.id,
    required this.utcDate,
    required this.status,
    required this.matchday,
    required this.stage,
    this.group,
    required this.homeTeamName,
    this.homeTeamCrest,
    required this.awayTeamName,
    this.awayTeamCrest,
    this.homeScore,
    this.awayScore,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'],
      utcDate: json['utc_date'],
      status: json['status'],
      matchday: json['matchday'] ?? 0,
      stage: json['stage'] ?? '',
      group: json['group'],
      homeTeamName: json['home_team']['name'] ?? 'A definir',
      homeTeamCrest: json['home_team']['crest'],
      awayTeamName: json['away_team']['name'] ?? 'A definir',
      awayTeamCrest: json['away_team']['crest'],
      homeScore: json['score']['full_time']['home'],
      awayScore: json['score']['full_time']['away'],
    );
  }
}