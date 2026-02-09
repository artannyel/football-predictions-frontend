class LeagueModel {
  final String id;
  final String name;
  final String code;
  final String? avatar;
  final String description;
  final LeagueCompetition competition;
  final LeagueOwner owner;
  final int membersCount;
  final int myPoints;

  LeagueModel({
    required this.id,
    required this.name,
    required this.code,
    this.avatar,
    required this.description,
    required this.competition,
    required this.owner,
    required this.membersCount,
    required this.myPoints,
  });

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    return LeagueModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      avatar: json['avatar'],
      description: json['description'] ?? '',
      competition: LeagueCompetition.fromJson(json['competition']),
      owner: LeagueOwner.fromJson(json['owner']),
      membersCount: json['members_count'] ?? 0,
      myPoints: json['my_points'] ?? 0,
    );
  }
}

class LeagueCompetition {
  final int id;
  final String name;
  final String? emblem;

  LeagueCompetition({required this.id, required this.name, this.emblem});

  factory LeagueCompetition.fromJson(Map<String, dynamic> json) {
    return LeagueCompetition(
      id: json['id'],
      name: json['name'],
      emblem: json['emblem'],
    );
  }
}

class LeagueOwner {
  final String id;
  final String name;
  final String? photoUrl;

  LeagueOwner({required this.id, required this.name, this.photoUrl});

  factory LeagueOwner.fromJson(Map<String, dynamic> json) {
    return LeagueOwner(
      id: json['id'],
      name: json['name'],
      photoUrl: json['photo_url'],
    );
  }
}