import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:football_predictions/dio_client.dart';
import 'package:football_predictions/features/admin/data/models/admin_badge_model.dart';
import 'package:football_predictions/features/admin/data/models/admin_log_model.dart';
import 'package:football_predictions/features/admin/data/models/admin_match_model.dart';
import 'package:image_picker/image_picker.dart';

class AdminRepository {
  final DioClient dioClient;

  AdminRepository({required this.dioClient});

  Future<AdminFiltersModel> getFilters() async {
    try {
      final response = await dioClient.dioAdmin.get('admin/filters');
      return AdminFiltersModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Falha ao carregar filtros: $e');
    }
  }

  Future<({List<AdminMatchModel> matches, int lastPage})> getMatches({
    int page = 1,
    String? status,
    int? competitionId,
    String? teamName,
    String? dateFrom,
    String? dateTo,
    bool stuck = false,
  }) async {
    try {
      final endpoint = stuck ? 'admin/matches/stuck' : 'admin/matches';
      final queryParams = <String, dynamic>{'page': page};

      if (!stuck) {
        if (status != null) queryParams['status'] = status;
        if (competitionId != null) queryParams['competition_id'] = competitionId;
        if (teamName != null && teamName.isNotEmpty) {
          queryParams['team_name'] = teamName;
        }
        if (dateFrom != null) queryParams['date_from'] = dateFrom;
        if (dateTo != null) queryParams['date_to'] = dateTo;
      }

      final response = await dioClient.dioAdmin.get(
        endpoint,
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data['data'];
      final meta = response.data['meta'] ?? {};

      return (
        matches: data.map((e) => AdminMatchModel.fromJson(e)).toList(),
        lastPage: (meta['last_page'] as int?) ?? 1,
      );
    } catch (e) {
      throw Exception('Falha ao carregar partidas: $e');
    }
  }

  Future<void> fixMatch({
    required int id,
    required bool unlock,
    String? status,
    int? homeScore,
    int? awayScore,
    int? homeScoreHalf,
    int? awayScoreHalf,
    int? homeScoreExtra,
    int? awayScoreExtra,
    int? homeScorePen,
    int? awayScorePen,
    String? winner,
    String? duration,
  }) async {
    try {
      final data = {
        'unlock': unlock,
        if (!unlock) ...{
          'status': status,
          'score_fulltime_home': homeScore,
          'score_fulltime_away': awayScore,
          'score_winner': winner,
          'score_duration': duration,
          'score_extra_time_home': homeScoreExtra,
          'score_extra_time_away': awayScoreExtra,
          'score_penalties_home': homeScorePen,
          'score_penalties_away': awayScorePen,
        }
      };
      await dioClient.dioAdmin.post('admin/matches/$id/fix', data: data);
    } catch (e) {
      throw Exception('Falha ao corrigir partida: $e');
    }
  }

  // --- Ferramentas de Sistema ---

  Future<void> importMatches({int? competitionId}) async {
    try {
      final data = {
        if (competitionId != null) 'competition_id': competitionId,
      };
      await dioClient.dioAdmin.post('admin/import-matches', data: data);
    } catch (e) {
      throw Exception('Falha ao importar partidas: $e');
    }
  }

  Future<void> recalculateStats() async {
    try {
      await dioClient.dioAdmin.post('admin/recalculate-stats');
    } catch (e) {
      throw Exception('Falha ao recalcular estatísticas: $e');
    }
  }

  Future<void> recalculateBadges({String? badgeSlug}) async {
    try {
      final data = {
        if (badgeSlug != null && badgeSlug.isNotEmpty) 'badge_slug': badgeSlug,
      };
      await dioClient.dioAdmin.post('admin/recalculate-badges', data: data);
    } catch (e) {
      throw Exception('Falha ao recalcular medalhas: $e');
    }
  }

  Future<void> recalculateGlobalStats() async {
    try {
      await dioClient.dioAdmin.post('admin/recalculate-global-stats');
    } catch (e) {
      throw Exception('Falha ao resetar ranking global: $e');
    }
  }

  Future<void> distributePowerups() async {
    try {
      await dioClient.dioAdmin.post('admin/distribute-powerups');
    } catch (e) {
      throw Exception('Falha ao distribuir power-ups: $e');
    }
  }

  Future<List<AdminLogModel>> getLogs() async {
    try {
      final response = await dioClient.dioAdmin.get('admin/logs');
      final List<dynamic> data = response.data['logs'];
      return data.map((e) => AdminLogModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Falha ao carregar logs: $e');
    }
  }

  Future<List<int>> downloadLog(String filename) async {
    try {
      final response = await dioClient.dioAdmin.get(
        'admin/logs/$filename',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      throw Exception('Falha ao baixar log: $e');
    }
  }

  // --- Medalhas (Badges) ---

  Future<List<AdminBadgeModel>> getBadges() async {
    try {
      final response = await dioClient.dioAdmin.get('admin/badges');
      final List<dynamic> data = response.data['data'];
      return data.map((e) => AdminBadgeModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Falha ao carregar medalhas: $e');
    }
  }

  Future<void> updateBadge({
    required String slug,
    required String name,
    required String description,
    XFile? iconFile,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('badges[0][slug]', slug));
      formData.fields.add(MapEntry('badges[0][name]', name));
      formData.fields.add(MapEntry('badges[0][description]', description));

      if (iconFile != null) {
        if (kIsWeb) {
          final bytes = await iconFile.readAsBytes();
          formData.files.add(MapEntry(
            'badges[0][icon_file]',
            MultipartFile.fromBytes(bytes, filename: iconFile.name),
          ));
        } else {
          formData.files.add(MapEntry(
            'badges[0][icon_file]',
            await MultipartFile.fromFile(iconFile.path, filename: iconFile.name),
          ));
        }
      }

      await dioClient.dioAdmin.post('admin/badges', data: formData);
    } catch (e) {
      throw Exception('Falha ao atualizar medalha: $e');
    }
  }
}
