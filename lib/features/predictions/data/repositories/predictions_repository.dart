import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:football_predictions/dio_client.dart';
import 'package:football_predictions/features/auth/data/models/user_model.dart';
import 'package:football_predictions/features/home/data/models/league_ranking_model.dart';
import 'package:football_predictions/features/predictions/data/models/prediction_model.dart';

class PredictionsRepository {
  final DioClient dioClient;

  PredictionsRepository({required this.dioClient});

  Future<void> savePrediction({
    required int matchId,
    required int homeScore,
    required int awayScore,
    required String leagueId,
  }) async {
    try {
      await dioClient.dio.post(
        'predictions',
        data: {
          'match_id': matchId,
          'home_score': homeScore,
          'away_score': awayScore,
          'league_id': leagueId,
        },
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? 'Erro ao salvar palpite')
          : 'Erro ao salvar palpite (${e.response?.statusCode})';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Falha ao salvar palpite: $e');
    }
  }

  Future<List<PredictionModel>> getUpcomingPredictions({
    String? leagueId,
  }) async {
    try {
      final queryParams = leagueId != null ? {'league_id': leagueId} : null;
      final response = await dioClient.dio.get(
        'predictions/upcoming',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data['data'];
      return data.map((json) => PredictionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? 'Erro ao carregar palpites ativos')
          : 'Erro ao carregar palpites ativos (${e.response?.statusCode})';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Falha ao carregar palpites ativos: $e');
    }
  }

  Future<({List<PredictionModel> predictions, int lastPage})> getPredictions({
    String? leagueId,
    int page = 1,
  }) async {
    try {
      final queryParams = {
        if (leagueId != null) 'league_id': leagueId,
        'page': page,
      };
      final response = await dioClient.dio.get(
        'predictions',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data['data'];
      final meta = response.data['meta'] ?? {};
      return (
        predictions: data
            .map((json) => PredictionModel.fromJson(json))
            .toList(),
        lastPage: (meta['last_page'] as int?) ?? 1,
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? 'Erro ao carregar histórico de palpites')
          : 'Erro ao carregar histórico de palpites (${e.response?.statusCode})';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Falha ao carregar histórico de palpites: $e');
    }
  }

  Future<PredictionModel> getPrediction(int id) async {
    try {
      final response = await dioClient.dio.get('predictions/$id');
      return PredictionModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      final errorMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? 'Erro ao carregar palpite')
          : 'Erro ao carregar palpite (${e.response?.statusCode})';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Falha ao carregar palpite: $e');
    }
  }

  Future<
    ({
      List<({PredictionModel user, PredictionModel? me})> predictions,
      int lastPage,
      RankingStatsModel? userStats,
      UserModel userModel,
      RankingStatsModel? meStats,
      UserModel? meModel,
    })
  >
  getUserPredictions({
    required String userId,
    required String leagueId,
    int page = 1,
  }) async {
    try {
      final response = await dioClient.dio.get(
        'predictions/user/$userId',
        queryParameters: {'league_id': leagueId, 'page': page},
      );

      final predictionsData = response.data['predictions'];
      final List<dynamic> data = predictionsData['data'];
      final meta = predictionsData['meta'] ?? {};

      final userData = response.data['user'];
      RankingStatsModel? userStats;
      UserModel userModel = UserModel.fromJson(userData);
      if (userData != null) {
        final statsData = userData['stats'] ?? {};
        userStats = RankingStatsModel.fromJson(statsData);
      }

      final meData = response.data['me'];
      RankingStatsModel? meStats;
      UserModel? meModel;
      if (meData != null) {
        meModel = UserModel.fromJson(meData);
        final statsData = meData['stats'] ?? {};
        meStats = RankingStatsModel.fromJson(statsData);
      }

      final predictions = data.map<({PredictionModel user, PredictionModel? me})>((json) {
        final userPred = PredictionModel.fromJson(json);
        PredictionModel? mePred;
        if (json['my_prediction'] != null && json['my_prediction'] is Map) {
          try {
            final myJson = Map<String, dynamic>.from(json['my_prediction']);
            
            // Injeta dados que faltam no my_prediction mas existem no prediction principal
            if (json['match'] != null) myJson['match'] = json['match'];
            if (json['match_id'] != null) myJson['match_id'] = json['match_id'];
            if (json['league_id'] != null) myJson['league_id'] = json['league_id'];
            if (meModel != null) myJson['user_id'] = meModel.id;
            if (json['created_at'] != null) myJson['created_at'] = json['created_at'];
            if (json['updated_at'] != null) myJson['updated_at'] = json['updated_at'];

            mePred = PredictionModel.fromJson(myJson);
          } catch (e) {
            debugPrint('Erro ao processar my_prediction: $e');
          }
        }
        return (user: userPred, me: mePred);
      }).toList();

      return (
        predictions: predictions,
        lastPage: (meta['last_page'] as int?) ?? 1,
        userStats: userStats,
        userModel: userModel,
        meStats: meStats,
        meModel: meModel,
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? 'Erro ao carregar palpites do usuário')
          : 'Erro ao carregar palpites do usuário (${e.response?.statusCode})';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Falha ao carregar palpites do usuário: $e');
    }
  }
}
