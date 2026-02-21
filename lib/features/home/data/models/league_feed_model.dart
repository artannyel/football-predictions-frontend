import 'package:football_predictions/features/auth/data/models/user_model.dart';

class LeagueFeedModel {
  final int id;
  final String createdAt;
  final UserModel user;
  final BadgeModel badge;
  final FeedMatchModel match;

  LeagueFeedModel({
    required this.id,
    required this.createdAt,
    required this.user,
    required this.badge,
    required this.match,
  });

  factory LeagueFeedModel.fromJson(Map<String, dynamic> json) {
    return LeagueFeedModel(
      id: json['id'],
      createdAt: json['created_at'],
      user: UserModel.fromJson(json['user']),
      badge: BadgeModel.fromJson(json['badge']),
      match: FeedMatchModel.fromJson(json['match']),
    );
  }
}

class FeedMatchModel {
  final int id;
  final String homeTeamName;
  final String? homeTeamCrest;
  final String awayTeamName;
  final String? awayTeamCrest;
  final int? homeScore;
  final int? awayScore;

  FeedMatchModel({
    required this.id,
    required this.homeTeamName,
    this.homeTeamCrest,
    required this.awayTeamName,
    this.awayTeamCrest,
    this.homeScore,
    this.awayScore,
  });

  factory FeedMatchModel.fromJson(Map<String, dynamic> json) {
    return FeedMatchModel(
      id: json['id'],
      homeTeamName: json['home_team']['name'],
      homeTeamCrest: json['home_team']['crest'],
      awayTeamName: json['away_team']['name'],
      awayTeamCrest: json['away_team']['crest'],
      homeScore: json['score']['home'],
      awayScore: json['score']['away'],
    );
  }
}