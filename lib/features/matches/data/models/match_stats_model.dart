class MatchStatsModel {
  final int total;
  final num homeWinPercentage;
  final num awayWinPercentage;
  final num drawPercentage;

  MatchStatsModel({
    required this.total,
    required this.homeWinPercentage,
    required this.awayWinPercentage,
    required this.drawPercentage,
  });

  factory MatchStatsModel.fromJson(Map<String, dynamic> json) {
    return MatchStatsModel(
      total: json['total'] ?? 0,
      homeWinPercentage: json['home_win_percentage'] ?? 0,
      awayWinPercentage: json['away_win_percentage'] ?? 0,
      drawPercentage: json['draw_percentage'] ?? 0,
    );
  }
}
