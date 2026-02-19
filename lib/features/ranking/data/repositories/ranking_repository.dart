import 'package:dio/dio.dart';
//import 'package:football_predictions/core/network/dio_client.dart';
import 'package:football_predictions/dio_client.dart';
import 'package:football_predictions/features/ranking/data/models/global_ranking_model.dart';
import 'package:football_predictions/features/ranking/data/models/global_rules_model.dart';

class RankingRepository {
  final DioClient _client;

  RankingRepository(this._client);

  Future<GlobalRankingModel> getGlobalRanking({String? period}) async {
    try {
      final response = await _client.dio.get(
        '/rankings/global',
        queryParameters: period != null ? {'period': period} : null,
      );
      return GlobalRankingModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erro ao carregar ranking');
    }
  }

  Future<GlobalRulesModel> getGlobalRules() async {
    try {
      final response = await _client.dio.get('/rules'); // Assumindo que rules vem daqui conforme prompt
      return GlobalRulesModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erro ao carregar regras');
    }
  }
}