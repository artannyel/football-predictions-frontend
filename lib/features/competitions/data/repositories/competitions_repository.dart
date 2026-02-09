import 'package:football_predictions/dio_client.dart';
import 'package:football_predictions/features/competitions/data/models/competition_model.dart';

class CompetitionsRepository {
  final DioClient dioClient;

  CompetitionsRepository({required this.dioClient});

  Future<List<CompetitionModel>> getCompetitions() async {
    try {
      final response = await dioClient.dio.get('competitions');
      
      final List<dynamic> data = response.data['data'];
      
      return data.map((json) => CompetitionModel.fromJson(json)).toList();
    } catch (e) {
      // Em um app real, trataríamos o erro de forma mais robusta
      throw Exception('Falha ao carregar competições: $e');
    }
  }
}