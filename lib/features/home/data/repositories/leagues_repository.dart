import 'package:football_predictions/dio_client.dart';
import 'package:football_predictions/features/home/data/models/league_details_model.dart';
import 'package:football_predictions/features/home/data/models/league_model.dart';
import 'package:football_predictions/features/home/data/models/league_ranking_model.dart';
import 'package:football_predictions/features/home/data/models/rule_model.dart';

class LeaguesRepository {
  final DioClient dioClient;

  LeaguesRepository({required this.dioClient});

  Future<List<LeagueModel>> getLeagues() async {
    try {
      final response = await dioClient.dio.get('leagues');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => LeagueModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Falha ao carregar ligas: $e');
    }
  }

  Future<void> createLeague({
    required String name,
    required int competitionId,
    String? description,
  }) async {
    try {
      await dioClient.dio.post('leagues', data: {
        'name': name,
        'competition_id': competitionId,
        'description': description,
      });
    } catch (e) {
      throw Exception('Falha ao criar liga: $e');
    }
  }

  Future<void> joinLeague(String code) async {
    try {
      await dioClient.dio.post('leagues/join', data: {
        'code': code,
      });
    } catch (e) {
      throw Exception('Falha ao entrar na liga: $e');
    }
  }

  Future<LeagueDetailsModel> getLeagueDetails(String id) async {
    try {
      final response = await dioClient.dio.get('leagues/$id');
      return LeagueDetailsModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Falha ao carregar detalhes da liga: $e');
    }
  }

  Future<List<LeagueRankingModel>> getLeagueRanking(String id) async {
    try {
      // Assumindo que existe um endpoint específico para o ranking
      final response = await dioClient.dio.get('leagues/$id/ranking');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => LeagueRankingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Falha ao carregar ranking: $e');
    }
  }

  Future<LeagueRulesModel> getRules() async {
    try {
      final response = await dioClient.dio.get('rules');
      final data = response.data;
      return LeagueRulesModel.fromJson(data);
    } catch (e) {
      throw Exception('Falha ao carregar regras: $e');
    }
  }
}