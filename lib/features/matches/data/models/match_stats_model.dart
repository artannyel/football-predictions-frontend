class MatchResultModel {
  final String result;
  final String score;
  final String opponent;
  final String date;
  final bool isHome;

  MatchResultModel({
    required this.result,
    required this.score,
    required this.opponent,
    required this.date,
    required this.isHome,
  });

  factory MatchResultModel.fromJson(Map<String, dynamic> json) {
    return MatchResultModel(
      result: json['result'] ?? '',
      score: json['score'] ?? '',
      opponent: json['opponent'] ?? '',
      date: json['date'] ?? '',
      isHome: json['is_home'] ?? false,
    );
  }
}

class TeamFormModel {
  final List<MatchResultModel> home;
  final List<MatchResultModel> away;

  TeamFormModel({required this.home, required this.away});

  factory TeamFormModel.fromJson(Map<String, dynamic> json) {
    return TeamFormModel(
      home: (json['home'] as List?)
              ?.map((e) => MatchResultModel.fromJson(e))
              .toList() ??
          [],
      away: (json['away'] as List?)
              ?.map((e) => MatchResultModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MatchStatsModel {
  final int total;
  final num homeWinPercentage;
  final num awayWinPercentage;
  final num drawPercentage;
  final TeamFormModel? form;

  MatchStatsModel({
    required this.total,
    required this.homeWinPercentage,
    required this.awayWinPercentage,
    required this.drawPercentage,
    this.form,
  });

  factory MatchStatsModel.fromJson(Map<String, dynamic> json) {
    return MatchStatsModel(
      total: json['total'] ?? 0,
      homeWinPercentage: json['home_win_percentage'] ?? 0,
      awayWinPercentage: json['away_win_percentage'] ?? 0,
      drawPercentage: json['draw_percentage'] ?? 0,
      form: json['form'] != null ? TeamFormModel.fromJson(json['form']) : null,
    );
  }
}
