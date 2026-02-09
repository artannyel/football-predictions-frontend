class RuleModel {
  final int points;
  final String title;
  final String description;
  final String example;

  RuleModel({
    required this.points,
    required this.title,
    required this.description,
    required this.example,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) {
    return RuleModel(
      points: json['points'],
      title: json['title'],
      description: json['description'],
      example: json['example'],
    );
  }
}

class TieBreakerModel {
  final int order;
  final String title;
  final String description;

  TieBreakerModel({
    required this.order,
    required this.title,
    required this.description,
  });

  factory TieBreakerModel.fromJson(Map<String, dynamic> json) {
    return TieBreakerModel(
      order: json['order'],
      title: json['title'],
      description: json['description'],
    );
  }
}

class LeagueRulesModel {
  final List<RuleModel> scoring;
  final List<TieBreakerModel> tieBreakers;

  LeagueRulesModel({
    required this.scoring,
    required this.tieBreakers,
  });

  factory LeagueRulesModel.fromJson(Map<String, dynamic> json) {
    return LeagueRulesModel(
      scoring: (json['scoring'] as List)
          .map((e) => RuleModel.fromJson(e))
          .toList(),
      tieBreakers: (json['tie_breakers'] as List)
          .map((e) => TieBreakerModel.fromJson(e))
          .toList(),
    );
  }
}