import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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
    XFile? avatar,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'competition_id': competitionId,
        if (description != null) 'description': description,
      });

      if (avatar != null) {
        if (kIsWeb) {
          // Na Web, lemos os bytes diretamente
          final bytes = await avatar.readAsBytes();
          formData.files.add(MapEntry(
            'avatar',
            MultipartFile.fromBytes(bytes, filename: avatar.name),
          ));
        } else {
          // No Mobile, usamos o caminho do arquivo
          formData.files.add(MapEntry(
            'avatar',
            await MultipartFile.fromFile(avatar.path, filename: avatar.name),
          ));
        }
      }

      final data = await dioClient.dio.post('leagues', data: formData);
      debugPrint('Resposta do servidor: ${data.data}');
    } on DioException catch (e) {
      debugPrint('Erro Dio: ${e.response?.statusCode} - ${e.response?.data}');

      // Tratamento específico para 302
      if (e.response?.statusCode == 302) {
        throw Exception('Sessão expirada ou erro de redirecionamento. Faça login novamente.');
      }

      // Tenta extrair a mensagem de erro amigável enviada pelo backend
      // Geralmente vem em campos como 'message', 'error' ou 'errors'
      final errorMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? 'Erro ao processar requisição')
          : 'Erro de conexão com o servidor (${e.response?.statusCode})';

      throw Exception(errorMessage);
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