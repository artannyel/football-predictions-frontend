import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:football_predictions/dio_client.dart';
import '../models/match_model.dart';

class MatchesRepository {
  final DioClient dioClient;

  MatchesRepository({required this.dioClient});

  Future<List<MatchModel>> getMatches({int? competitionId}) async {
    try {
      final String endpoint = competitionId != null
          ? 'competitions/$competitionId/matches'
          : 'matches';
      final response = await dioClient.dio.get(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> matchesList = response.data['data'];
        return matchesList.map((json) => MatchModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Erro ao carregar partidas: ${e.message}');
      throw Exception('Falha ao carregar partidas: ${e.message}');
    }
  }

  Future<List<MatchModel>> getMatchesPredictions({int? competitionId}) async {
    try {
      final String endpoint = competitionId != null
          ? 'competitions/$competitionId/matches/upcoming'
          : 'matches';
      final response = await dioClient.dio.get(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> matchesList = response.data['data'];
        return matchesList.map((json) => MatchModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Erro ao carregar partidas: ${e.message}');
      throw Exception('Falha ao carregar partidas: ${e.message}');
    }
  }
}