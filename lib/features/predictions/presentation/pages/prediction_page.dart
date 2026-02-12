import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/matches/data/models/match_model.dart';
import 'package:football_predictions/features/home/data/repositories/leagues_repository.dart';
import 'package:football_predictions/features/predictions/data/repositories/predictions_repository.dart';
import 'package:provider/provider.dart';

class PredictionPage extends StatefulWidget {
  final int matchId;
  final String leagueId;
  final int? predictionId;

  const PredictionPage({
    super.key,
    required this.matchId,
    required this.leagueId,
    this.predictionId,
  });

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _homeScoreController = TextEditingController();
  final _awayScoreController = TextEditingController();
  bool _isLoading = false;
  bool _isFetching = false;
  MatchModel? _match;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isFetching = true;
      _errorMessage = null;
    });
    try {
      // Carrega a partida
      final match = await context.read<LeaguesRepository>().getMatch(
        widget.matchId,
      );

      // Se tiver ID de palpite, carrega o palpite também
      if (widget.predictionId != null) {
        final prediction = await context
            .read<PredictionsRepository>()
            .getPrediction(widget.predictionId!);

        if (prediction.match.id != match.id) {
          throw Exception('O palpite não corresponde à partida selecionada.');
        }

        if (mounted) {
          _homeScoreController.text = prediction.homeScore.toString();
          _awayScoreController.text = prediction.awayScore.toString();
        }
      }

      if (mounted) {
        setState(() => _match = match);
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.response?.data is Map
              ? (e.response?.data['message'] ??
                    e.message ??
                    'Erro desconhecido')
              : (e.message ?? 'Erro desconhecido');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  @override
  void dispose() {
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    super.dispose();
  }

  Future<void> _savePrediction() async {
    final homeScore = int.tryParse(_homeScoreController.text);
    final awayScore = int.tryParse(_awayScoreController.text);

    if (homeScore == null || awayScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um placar válido.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<PredictionsRepository>().savePrediction(
        matchId: widget.matchId,
        homeScore: homeScore,
        awayScore: awayScore,
        leagueId: widget.leagueId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Palpite salvo com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } on DioException catch (e) {
      if (mounted) {
        final message = e.response?.data is Map
            ? (e.response?.data['message'] ?? e.message ?? 'Erro desconhecido')
            : (e.message ?? 'Erro desconhecido');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String utcDate) {
    final dateTime = DateTime.parse(utcDate).toLocal();
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fazer Palpite')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isFetching) {
      return const Center(child: LoadingWidget());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('VOLTAR'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_match == null) {
      return const Center(child: LoadingWidget());
    }

    final matchDate = DateTime.parse(_match!.utcDate).toLocal();
    final hasStarted = DateTime.now().isAfter(matchDate);
    final isLocked =
        hasStarted ||
        (_match!.status != 'SCHEDULED' && _match!.status != 'TIMED');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Rodada ${_match!.matchday}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(_match!.utcDate),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamColumn(_match!.homeTeamName, _match!.homeTeamCrest),
              const Text(
                'X',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              _buildTeamColumn(_match!.awayTeamName, _match!.awayTeamCrest),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreInput(_homeScoreController, !isLocked),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('-', style: TextStyle(fontSize: 24)),
              ),
              _buildScoreInput(_awayScoreController, !isLocked),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isLoading || isLocked ? null : _savePrediction,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _match!.status == 'FINISHED'
                          ? 'PARTIDA ENCERRADA'
                          : (isLocked
                                ? 'PARTIDA JÁ INICIOU'
                                : 'SALVAR PALPITE'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(String name, String? crest) {
    return Expanded(
      child: Column(
        children: [
          if (crest != null)
            AppNetworkImage(
              url: crest,
              height: 64,
              width: 64,
              errorWidget: const Icon(Icons.sports_soccer, size: 64),
            )
          else
            const Icon(Icons.sports_soccer, size: 64),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInput(TextEditingController controller, bool enabled) {
    return SizedBox(
      width: 60,
      child: TextField(
        enabled: enabled,
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
