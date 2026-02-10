import 'package:football_predictions/features/home/data/models/league_model.dart';

class LeagueDetailsModel {
  final String id;
  final String name;
  final String code;
  final String? avatar;
  final String description;
  final LeagueCompetition competition;
  final LeagueOwner owner;
  final int membersCount;
  final bool isActive;

  LeagueDetailsModel({
    required this.id,
    required this.name,
    required this.code,
    this.avatar,
    required this.description,
    required this.competition,
    required this.owner,
    required this.membersCount,
    required this.isActive,
  });

  factory LeagueDetailsModel.fromJson(Map<String, dynamic> json) {
    return LeagueDetailsModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      avatar: json['avatar'],
      description: json['description'] ?? '',
      competition: LeagueCompetition.fromJson(json['competition']),
      owner: LeagueOwner.fromJson(json['owner']),
      membersCount: json['members_count'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}