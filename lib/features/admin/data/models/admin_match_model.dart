class AdminMatchModel {
  final int id;
  final String utcDate;
  final String status;
  final int matchday;
  final String stage;
  final String competitionName;
  final String homeTeamName;
  final String awayTeamName;
  final int? homeScore;
  final int? awayScore;
  final int? homeScoreHalfTime;
  final int? awayScoreHalfTime;
  final int? homeScoreExtraTime;
  final int? awayScoreExtraTime;
  final int? homeScorePenalties;
  final int? awayScorePenalties;
  final String? winner;
  final String? duration;
  final bool isManualUpdate;

  AdminMatchModel({
    required this.id,
    required this.utcDate,
    required this.status,
    required this.matchday,
    required this.stage,
    required this.competitionName,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeScore,
    this.awayScore,
    this.homeScoreHalfTime,
    this.awayScoreHalfTime,
    this.homeScoreExtraTime,
    this.awayScoreExtraTime,
    this.homeScorePenalties,
    this.awayScorePenalties,
    this.winner,
    this.duration,
    required this.isManualUpdate,
  });

  factory AdminMatchModel.fromJson(Map<String, dynamic> json) {
    final score = json['score'] ?? {};
    final fullTime = score['full_time'] ?? {};
    final halfTime = score['half_time'] ?? {};
    final extraTime = score['extra_time'] ?? {};
    final penalties = score['penalties'] ?? {};

    return AdminMatchModel(
      id: json['id'],
      utcDate: json['utc_date'],
      status: json['status'],
      matchday: json['matchday'] ?? 0,
      stage: json['stage'] ?? '',
      competitionName: json['competition']?['name'] ?? 'Desconhecida',
      homeTeamName: json['home_team']['name'],
      awayTeamName: json['away_team']['name'],
      homeScore: fullTime['home'],
      awayScore: fullTime['away'],
      homeScoreHalfTime: halfTime['home'],
      awayScoreHalfTime: halfTime['away'],
      homeScoreExtraTime: extraTime['home'],
      awayScoreExtraTime: extraTime['away'],
      homeScorePenalties: penalties['home'],
      awayScorePenalties: penalties['away'],
      winner: score['winner'],
      duration: score['duration'],
      isManualUpdate: json['is_manual_update'] ?? false,
    );
  }
}

class AdminFiltersModel {
  final List<AdminFilterItem> competitions;
  final List<String> statuses;

  AdminFiltersModel({
    required this.competitions,
    required this.statuses,
  });

  factory AdminFiltersModel.fromJson(Map<String, dynamic> json) {
    return AdminFiltersModel(
      competitions: (json['competitions'] as List?)
              ?.map((e) => AdminFilterItem.fromJson(e))
              .toList() ??
          [],
      statuses: (json['statuses'] as List?)?.cast<String>() ?? [],
    );
  }
}

class AdminFilterItem {
  final int id;
  final String name;

  AdminFilterItem({required this.id, required this.name});

  factory AdminFilterItem.fromJson(Map<String, dynamic> json) {
    return AdminFilterItem(id: json['id'], name: json['name']);
  }
}
