class RankingStatsModel {
  final int? points;
  final int exactScore;
  final int winnerDiff;
  final int winnerGoal;
  final int winnerOnly;
  final int errors;
  final int total;

  RankingStatsModel({
    this.points,
    required this.exactScore,
    required this.winnerDiff,
    required this.winnerGoal,
    required this.winnerOnly,
    required this.errors,
    required this.total,
  });

  factory RankingStatsModel.fromJson(Map<String, dynamic> json) {
    return RankingStatsModel(
      points: json['points'],
      exactScore: json['exact_score'] ?? 0,
      winnerDiff: json['winner_diff'] ?? 0,
      winnerGoal: json['winner_goal'] ?? 0,
      winnerOnly: json['winner_only'] ?? 0,
      errors: json['errors'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class LeagueRankingModel {
  final int rank;
  final String id;
  final String name;
  final String? photoUrl;
  final int points;
  final RankingStatsModel stats;

  LeagueRankingModel({
    required this.rank,
    required this.id,
    required this.name,
    this.photoUrl,
    required this.points,
    required this.stats,
  });

  factory LeagueRankingModel.fromJson(Map<String, dynamic> json) {
    return LeagueRankingModel(
      rank: json['rank'] ?? 0,
      id: json['user_id'],
      name: json['name'],
      photoUrl: json['photo_url'],
      points: json['points'] ?? 0,
      stats: RankingStatsModel.fromJson(json['stats'] ?? {}),
    );
  }
}