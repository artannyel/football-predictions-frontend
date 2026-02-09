import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import '../../data/models/match_model.dart';
import '../../data/repositories/matches_repository.dart';

class MatchesPage extends StatefulWidget {
  final int competitionId;
  final String competitionName;

  const MatchesPage(
      {super.key, required this.competitionId, required this.competitionName});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  late Future<List<MatchModel>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = context
        .read<MatchesRepository>()
        .getMatches(competitionId: widget.competitionId);
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

  String _translateStage(String stage) {
    switch (stage) {
      case 'REGULAR_SEASON':
        return 'Temporada Regular';
      case 'GROUP_STAGE':
        return 'Fase de Grupos';
      case 'LAST_16':
        return 'Oitavas de Final';
      case 'QUARTER_FINALS':
        return 'Quartas de Final';
      case 'SEMI_FINALS':
        return 'Semifinais';
      case 'FINAL':
        return 'Final';
      default:
        return stage.replaceAll('_', ' ');
    }
  }

  String _formatMatchday(String stage, int matchday) {
    const knockoutStages = [
      'LAST_16',
      'QUARTER_FINALS',
      'SEMI_FINALS',
      'FINAL'
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
        title: Text(widget.competitionName),
      ),
      body: FutureBuilder<List<MatchModel>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erro ao carregar partidas:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma partida encontrada.'));
          }

          final matches = snapshot.data!;
          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            if (match.homeTeamCrest != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: AppNetworkImage(
                                  url: match.homeTeamCrest!,
                                  width: 20,
                                  height: 20,
                                  errorWidget: const Icon(Icons.sports_soccer, size: 20),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          '${match.homeScore ?? '-'} x ${match.awayScore ?? '-'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (match.awayTeamCrest != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: AppNetworkImage(
                                  url: match.awayTeamCrest!,
                                  width: 20,
                                  height: 20,
                                  errorWidget: const Icon(Icons.sports_soccer, size: 20),
                                ),
                              ),
                            Flexible(
                              child: Text(match.awayTeamName,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: match.status == 'IN_PLAY'
                            ? const _BlinkingLiveIndicator()
                            : Text(_translateStatus(match.status)),
                      ),
                      const SizedBox(height: 4),
                      Text(_translateStage(match.stage)),
                      if (match.group != null)
                        Text(match.group!.replaceAll('_', ' ')),
                      const SizedBox(height: 4),
                      Text(
                        _formatMatchday(match.stage, match.matchday),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(match.utcDate),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BlinkingLiveIndicator extends StatefulWidget {
  const _BlinkingLiveIndicator();

  @override
  State<_BlinkingLiveIndicator> createState() => _BlinkingLiveIndicatorState();
}

class _BlinkingLiveIndicatorState extends State<_BlinkingLiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.red, size: 10),
          SizedBox(width: 4),
          Text(
            'AO VIVO',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}