import 'package:football_predictions/features/matches/data/models/match_model.dart';

class PredictionModel {
  final int id;
  final int matchId;
  final int homeScore;
  final int awayScore;
  final int? pointsEarned;
  final String createdAt;
  final MatchModel match;

  PredictionModel({
    required this.id,
    required this.matchId,
    required this.homeScore,
    required this.awayScore,
    this.pointsEarned,
    required this.createdAt,
    required this.match,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['id'],
      matchId: json['match_id'],
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      pointsEarned: json['points_earned'],
      createdAt: json['created_at'],
      match: MatchModel.fromJson(json['match']),
    );
  }
}