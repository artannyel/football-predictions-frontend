import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/matches/data/models/match_model.dart';
import 'package:football_predictions/features/predictions/data/repositories/predictions_repository.dart';
import 'package:provider/provider.dart';

class PredictionPage extends StatefulWidget {
  final MatchModel match;
  final String leagueId;
  final int? predictionId;

  const PredictionPage({
    super.key,
    required this.match,
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

  @override
  void initState() {
    super.initState();
    if (widget.predictionId != null) {
      _fetchPrediction();
    }
  }

  Future<void> _fetchPrediction() async {
    setState(() => _isFetching = true);
    try {
      final prediction = await context
          .read<PredictionsRepository>()
          .getPrediction(widget.predictionId!);
      if (mounted) {
        _homeScoreController.text = prediction.homeScore.toString();
        _awayScoreController.text = prediction.awayScore.toString();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar palpite: $e')),
        );
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
            matchId: widget.match.id,
            homeScore: homeScore,
            awayScore: awayScore,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Palpite salvo com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer Palpite'),
      ),
      body: _isFetching
          ? const Center(child: LoadingWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Rodada ${widget.match.matchday}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTeamColumn(
                        widget.match.homeTeamName,
                        widget.match.homeTeamCrest,
                      ),
                      const Text('X',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      _buildTeamColumn(
                        widget.match.awayTeamName,
                        widget.match.awayTeamCrest,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildScoreInput(_homeScoreController),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('-', style: TextStyle(fontSize: 24)),
                      ),
                      _buildScoreInput(_awayScoreController),
                    ],
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _savePrediction,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SALVAR PALPITE'),
                    ),
                  ),
                ],
              ),
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

  Widget _buildScoreInput(TextEditingController controller) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}