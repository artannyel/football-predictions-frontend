import 'package:football_predictions/dio_client.dart';
import 'package:football_predictions/features/predictions/data/models/prediction_model.dart';

class PredictionsRepository {
  final DioClient dioClient;

  PredictionsRepository({required this.dioClient});

  Future<void> savePrediction({
    required int matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    try {
      await dioClient.dio.post('predictions', data: {
        'match_id': matchId,
        'home_score': homeScore,
        'away_score': awayScore,
      });
    } catch (e) {
      throw Exception('Falha ao salvar palpite: $e');
    }
  }

  Future<List<PredictionModel>> getUpcomingPredictions(
      {int? competitionId}) async {
    try {
      final queryParams = competitionId != null ? {'competition_id': competitionId} : null;
      final response = await dioClient.dio.get('predictions/upcoming', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => PredictionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Falha ao carregar palpites ativos: $e');
    }
  }

  Future<List<PredictionModel>> getPredictions({int? competitionId}) async {
    try {
      final queryParams = competitionId != null ? {'competition_id': competitionId} : null;
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