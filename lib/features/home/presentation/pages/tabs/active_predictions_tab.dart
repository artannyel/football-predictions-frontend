import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/blinking_live_indicator.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/core/presentation/widgets/web_constrained_box.dart';
import 'package:football_predictions/features/predictions/data/models/prediction_model.dart';
import 'package:football_predictions/features/predictions/data/repositories/predictions_repository.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'league_ui_helpers.dart';

class ActivePredictionsTab extends StatelessWidget {
  final String leagueId;
  final VoidCallback onRefreshDetails;

  const ActivePredictionsTab({
    super.key,
    required this.leagueId,
    required this.onRefreshDetails,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PredictionModel>>(
      future: context.read<PredictionsRepository>().getUpcomingPredictions(
        leagueId: leagueId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        } else if (snapshot.hasError) {
          return buildScrollablePlaceholder(
            Text(
              'Erro ao carregar palpites:\n${snapshot.error.toString().replaceAll('Exception: ', '')}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return buildScrollablePlaceholder(
            const Text('Nenhum palpite encontrado.'),
          );
        }

        final predictions = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            final prediction = predictions[index];
            final match = prediction.match;
            final matchDate = DateTime.parse(match.utcDate);
            final hasStarted = DateTime.now().isAfter(matchDate);
            final isEditable =
                (match.status == 'SCHEDULED' || match.status == 'TIMED') &&
                !hasStarted;

            return WebConstrainedBox(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(prediction.id),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(math.pi / 2 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: GlassCard(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: isEditable
                        ? () async {
                            final result = await context.pushNamed(
                              'Prediction',
                              pathParameters: {
                                'id': leagueId,
                                'matchId': match.id.toString(),
                              },
                              queryParameters: {
                                'predictionId': prediction.id.toString(),
                              },
                            );
                            if (result == true && context.mounted) {
                              onRefreshDetails();
                            }
                          }
                        : null,
                    child: Column(
                      children: [
                        // Header: Rodada e Data
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${translateStage(match.stage)} • ${formatMatchday(match.stage, match.matchday)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatDate(match.utcDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        // Corpo: Times e Placar
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    buildTeamLogo(match.homeTeamCrest),
                                    const SizedBox(height: 8),
                                    Text(
                                      match.homeTeamName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      '${match.homeScore ?? '-'} - ${match.awayScore ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    match.status == 'IN_PLAY'
                                        ? const BlinkingLiveIndicator()
                                        : Text(
                                            translateStatus(match.status),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    buildTeamLogo(match.awayTeamCrest),
                                    const SizedBox(height: 8),
                                    Text(
                                      match.awayTeamName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Footer: Palpite
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: buildPredictionCard(
                            context,
                            prediction,
                            'Seu palpite',
                            Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}