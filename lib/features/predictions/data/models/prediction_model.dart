import 'package:football_predictions/features/auth/data/models/user_model.dart';
import 'package:football_predictions/features/matches/data/models/match_model.dart';

class PredictionModel {
  final int id;
  final int matchId;
  final String leagueId;
  final int? homeScore;
  final int? awayScore;
  final int? pointsEarned;
  final String? createdAt;
  final MatchModel match;
  final String? powerupUsed;
  final List<BadgeModel> badges;

  PredictionModel({
    required this.id,
    required this.matchId,
    required this.leagueId,
    required this.homeScore,
    required this.awayScore,
    this.pointsEarned,
    required this.createdAt,
    required this.match,
    this.powerupUsed,
    this.badges = const [],
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['id'],
      matchId: json['match_id'],
      leagueId: json['league_id'].toString(),
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      pointsEarned: json['points_earned'],
      createdAt: json['created_at'],
      match: MatchModel.fromJson(json['match']),
      powerupUsed: json['powerup_used'],
      badges: (json['badges'] as List?)
              ?.map((e) => BadgeModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}