import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:football_predictions/features/predictions/data/models/prediction_model.dart';
import 'package:football_predictions/features/predictions/data/repositories/predictions_repository.dart';
import 'package:provider/provider.dart';

class UserPredictionsPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String leagueId;

  const UserPredictionsPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.leagueId,
  });

  @override
  State<UserPredictionsPage> createState() => _UserPredictionsPageState();
}

class _UserPredictionsPageState extends State<UserPredictionsPage> {
  final List<PredictionModel> _predictions = [];
  int _page = 1;
  int _lastPage = 1;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    if (_isLoading || _page > _lastPage) return;

    setState(() => _isLoading = true);

    try {
      final result = await context
          .read<PredictionsRepository>()
          .getUserPredictions(
            userId: widget.userId,
            leagueId: widget.leagueId,
            page: _page,
          );

      if (mounted) {
        setState(() {
          _predictions.addAll(result.predictions);
          _lastPage = result.lastPage;
          _page++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
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

  String _translateStatus(String status) {
    switch (status) {
      case 'SCHEDULED':
      case 'TIMED':
        return 'Agendado';
      case 'IN_PLAY':
        return 'Em andamento';
      case 'PAUSED':
        return 'Intervalo';
      case 'FINISHED':
        return 'Encerrado';
      case 'SUSPENDED':
        return 'Suspenso';
      case 'POSTPONED':
        return 'Adiado';
      case 'CANCELLED':
        return 'Cancelado';
      case 'AWARDED':
        return 'W.O.';
      default:
        return status;
    }
  }

  String _formatMatchday(String stage, int matchday) {
    const knockoutStages = [
      'LAST_16',
      'QUARTER_FINALS',
      'SEMI_FINALS',
      'FINAL',
    ];

    if (knockoutStages.contains(stage)) {
      if (matchday == 1) return 'Ida';
      if (matchday == 2) return 'Volta';
      if (matchday == 0) return 'Único';
    }
    return 'Rodada $matchday';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Palpites de ${widget.userName}'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.fill,
              colorBlendMode: BlendMode.darken,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_predictions.isEmpty && _isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (_predictions.isEmpty && _error != null) {
      return Center(
        child: Text(
          'Erro: $_error',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (_predictions.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum palpite encontrado.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isLoading &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _loadPredictions();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _predictions.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _predictions.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: LoadingWidget(size: 30)),
            );
          }

          final prediction = _predictions[index];
          final match = prediction.match;

          return GlassCard(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            match.homeTeamName,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: match.homeTeamCrest != null
                              ? AppNetworkImage(
                                  url: match.homeTeamCrest!,
                                  width: 20,
                                  height: 20,
                                  errorWidget: const Icon(
                                    Icons.sports_soccer,
                                    size: 20,
                                  ),
                                )
                              : const Icon(Icons.sports_soccer, size: 20),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      children: [
                        const Text('Palpite', style: TextStyle(fontSize: 10)),
                        Text(
                          '${prediction.homeScore} x ${prediction.awayScore}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (match.homeScore != null &&
                            match.awayScore != null) ...[
                          const SizedBox(height: 4),
                          const Text('Placar', style: TextStyle(fontSize: 10)),
                          Text(
                            '${match.homeScore} x ${match.awayScore}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: match.awayTeamCrest != null
                              ? AppNetworkImage(
                                  url: match.awayTeamCrest!,
                                  width: 20,
                                  height: 20,
                                  errorWidget: const Icon(
                                    Icons.sports_soccer,
                                    size: 20,
                                  ),
                                )
                              : const Icon(Icons.sports_soccer, size: 20),
                        ),
                        Flexible(
                          child: Text(
                            match.awayTeamName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _formatMatchday(match.stage, match.matchday),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_formatDate(match.utcDate)),
                    const SizedBox(height: 4),
                    Text(_translateStatus(match.status)),
                    if (prediction.pointsEarned != null)
                      Text(
                        'Pontos ganhos: ${prediction.pointsEarned}',
                        style: TextStyle(
                          color: prediction.pointsEarned == 0
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}