class GlobalRankingModel {
  final String period;
  final GlobalRankingUser? myRank;
  final List<GlobalRankingUser> topList;

  GlobalRankingModel({
    required this.period,
    this.myRank,
    required this.topList,
  });

  factory GlobalRankingModel.fromJson(Map<String, dynamic> json) {
    return GlobalRankingModel(
      period: json['period'] ?? 'GLOBAL',
      myRank: json['my_rank'] != null
          ? GlobalRankingUser.fromJson(json['my_rank'])
          : null,
      topList: (json['top_list'] as List?)
              ?.map((e) => GlobalRankingUser.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class GlobalRankingUser {
  final int rank;
  final String? userId; // Pode ser null no my_rank se vier de estrutura diferente, mas no top_list tem
  final String name;
  final String? photoUrl;
  final int points;
  final GlobalRankingStats stats;

  GlobalRankingUser({
    required this.rank,
    this.userId,
    required this.name,
    this.photoUrl,
    required this.points,
    required this.stats,
  });

  factory GlobalRankingUser.fromJson(Map<String, dynamic> json) {
    return GlobalRankingUser(
      rank: json['rank'],
      userId: json['user_id'],
      name: json['name'] ?? 'Usuário',
      photoUrl: json['photo_url'],
      points: json['points'] ?? 0,
      stats: GlobalRankingStats.fromJson(json['stats'] ?? {}),
    );
  }
}

class GlobalRankingStats {
  final int exactScore;
  final int winnerDiff;
  final int winnerGoal;
  final int winnerOnly;
  final int errors;
  final int total;

  GlobalRankingStats({
    required this.exactScore,
    required this.winnerDiff,
    required this.winnerGoal,
    required this.winnerOnly,
    required this.errors,
    required this.total,
  });

  factory GlobalRankingStats.fromJson(Map<String, dynamic> json) {
    return GlobalRankingStats(
      exactScore: json['exact_score'] ?? 0,
      winnerDiff: json['winner_diff'] ?? 0,
      winnerGoal: json['winner_goal'] ?? 0,
      winnerOnly: json['winner_only'] ?? 0,
      errors: json['errors'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}