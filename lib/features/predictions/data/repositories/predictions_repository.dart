import 'package:football_predictions/dio_client.dart';
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
      await dioClient.dio.post('predictions', data: {
        'match_id': matchId,
        'home_score': homeScore,
        'away_score': awayScore,
        'league_id': leagueId,
      });
    } catch (e) {
      throw Exception('Falha ao salvar palpite: $e');
    }
  }

  Future<List<PredictionModel>> getUpcomingPredictions(
      {String? leagueId}) async {
    try {
      final queryParams = leagueId != null ? {'league_id': leagueId} : null;
      final response = await dioClient.dio.get('predictions/upcoming', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => PredictionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Falha ao carregar palpites ativos: $e');
    }
  }

  Future<List<PredictionModel>> getPredictions({String? leagueId}) async {
    try {
      final queryParams = leagueId != null ? {'league_id': leagueId} : null;
      final response = await dioClient.dio.get('predictions', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => PredictionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Falha ao carregar histórico de palpites: $e');
    }
  }

  Future<PredictionModel> getPrediction(int id) async {
    try {
      final response = await dioClient.dio.get('predictions/$id');
      return PredictionModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Falha ao carregar palpite: $e');
    }
  }
}