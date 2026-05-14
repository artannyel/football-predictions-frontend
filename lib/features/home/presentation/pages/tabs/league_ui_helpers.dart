import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/web_constrained_box.dart';
import 'package:football_predictions/features/predictions/data/models/prediction_model.dart';

String formatRelativeTime(String utcDate) {
  final dateTime = DateTime.parse(utcDate).toLocal();
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    final seconds = math.max(0, difference.inSeconds);
    return 'Há $seconds ${seconds == 1 ? "segundo" : "segundos"}';
  } else if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return 'Há $minutes ${minutes == 1 ? "minuto" : "minutos"}';
  } else if (difference.inHours < 24) {
    final hours = difference.inHours;
    return 'Há $hours ${hours == 1 ? "hora" : "horas"}';
  } else if (difference.inDays < 30) {
    final days = difference.inDays;
    return 'Há $days ${days == 1 ? "dia" : "dias"}';
  } else {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$day/$month/$year';
  }
}

Widget buildTeamLogo(String? url) {
  return SizedBox(
    width: 48,
    height: 48,
    child: url != null
        ? AppNetworkImage(
            url: url,
            fit: BoxFit.contain,
            errorWidget: const Icon(Icons.sports_soccer, size: 32),
          )
        : const Icon(Icons.sports_soccer, size: 32),
  );
}

Widget buildScrollablePlaceholder(Widget child) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: WebConstrainedBox(child: child)),
        ),
      );
    },
  );
}

String formatDate(String utcDate) {
  final dateTime = DateTime.parse(utcDate).toLocal();
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

String translateStatus(String status) {
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

String translateStage(String stage) {
  switch (stage) {
    case 'REGULAR_SEASON':
      return 'Temporada Regular';
    case 'GROUP_STAGE':
      return 'Fase de Grupos';
    case 'PLAYOFFS':
      return 'Playoffs';
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

String formatMatchday(String stage, int matchday) {
  const knockoutStages = [
    'PLAYOFFS',
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

Widget buildPredictionCard(
  BuildContext context,
  PredictionModel? prediction,
  String label,
  Color color,
) {
  if (prediction == null ||
      prediction.homeScore == null ||
      prediction.awayScore == null) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '-',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  final points = prediction.pointsEarned ?? 0;
  final isWin = points > 0;
  final pointsText = points > 0 ? '+$points' : '$points';
  final powerupUsed = prediction.powerupUsed != null;
  final badges = prediction.badges;

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: isWin
          ? color.withValues(alpha: 0.15)
          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isWin
            ? color.withValues(alpha: 0.6)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        width: 1,
      ),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${prediction.homeScore} - ${prediction.awayScore}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (prediction.pointsEarned != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isWin ? color : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pointsText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isWin ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ],
            if (powerupUsed) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.style, size: 10, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      'x2',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (badges.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: badges.map((badge) {
              return Tooltip(
                message: badge.name,
                triggerMode: TooltipTriggerMode.tap,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: badge.iconUrl != null
                      ? AppNetworkImage(url: badge.iconUrl!)
                      : Icon(Icons.military_tech, size: 12, color: color),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    ),
  );
}