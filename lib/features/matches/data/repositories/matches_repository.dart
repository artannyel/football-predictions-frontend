import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:football_predictions/dio_client.dart';
import 'package:football_predictions/features/competitions/data/models/competition_model.dart';
import '../models/match_model.dart';

class MatchesRepository {
  final DioClient dioClient;

  MatchesRepository({required this.dioClient});

  Future<({CompetitionModel competition, List<MatchModel> matches})> getMatches({int? competitionId}) async {
    try {
      final String endpoint = competitionId != null
          ? 'competitions/$competitionId/matches'
          : 'matches';
      final response = await dioClient.dio.get(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        final competition = CompetitionModel.fromJson(response.data['competition']);
        final List<dynamic> matchesList = response.data['data'];
        final matches = matchesList.map((json) => MatchModel.fromJson(json)).toList();
        return (competition: competition, matches: matches);
      }
      throw Exception('Resposta inválida do servidor');
    } on DioException catch (e) {
      debugPrint('Erro ao carregar partidas: ${e.message}');
      throw Exception('Falha ao carregar partidas: ${e.message}');
    }
  }
}