import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/core/presentation/widgets/web_constrained_box.dart';
import 'package:football_predictions/features/home/data/models/league_ranking_model.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:go_router/go_router.dart';
import 'league_ui_helpers.dart';

class RankingTab extends StatelessWidget {
  final String? rankingError;
  final List<LeagueRankingModel> rankings;
  final bool isRankingLoading;
  final String? currentUserId;
  final bool isLeagueActive;
  final VoidCallback onLoadMore;
  final String leagueId;

  const RankingTab({
    super.key,
    required this.rankingError,
    required this.rankings,
    required this.isRankingLoading,
    required this.currentUserId,
    required this.isLeagueActive,
    required this.onLoadMore,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context) {
    if (rankingError != null && rankings.isEmpty) {
      return buildScrollablePlaceholder(
        Text('Erro ao carregar ranking: $rankingError'),
      );
    }

    if (rankings.isEmpty && isRankingLoading) {
      return const LoadingWidget();
    }

    if (rankings.isEmpty) {
      return buildScrollablePlaceholder(
        const Text('Nenhum participante encontrado.'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!isRankingLoading &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: ListView(
        key: const PageStorageKey('ranking'),
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          WebConstrainedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double fixedColumnsWidth = 350;
                        final double availableWidth = constraints.maxWidth;
                        final double nameWidth =
                            (availableWidth - fixedColumnsWidth).clamp(
                              150.0,
                              440.0,
                            );

                        return Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              showCheckboxColumn: false,
                              columnSpacing: 20,
                              headingRowHeight: 40,
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 48,
                              columns: [
                                const DataColumn(
                                  label: Text('#'),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: nameWidth,
                                    child: const Text(
                                      'Nome',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const DataColumn(
                                  label: Text('Pts'),
                                  numeric: true,
                                ),
                                const DataColumn(
                                  label: Tooltip(
                                    message: 'Placar Exato',
                                    triggerMode: TooltipTriggerMode.tap,
                                    child: Text('PE'),
                                  ),
                                  numeric: true,
                                ),
                                const DataColumn(
                                  label: Tooltip(
                                    message: 'Vencedor + Saldo',
                                    triggerMode: TooltipTriggerMode.tap,
                                    child: Text('VS'),
                                  ),
                                  numeric: true,
                                ),
                                const DataColumn(
                                  label: Tooltip(
                                    message: 'Vencedor + Gols',
                                    triggerMode: TooltipTriggerMode.tap,
                                    child: Text('VG'),
                                  ),
                                  numeric: true,
                                ),
                                const DataColumn(
                                  label: Tooltip(
                                    message: 'Apenas Vencedor',
                                    triggerMode: TooltipTriggerMode.tap,
                                    child: Text('AV'),
                                  ),
                                  numeric: true,
                                ),
                                const DataColumn(
                                  label: Tooltip(
                                    message: 'Erros',
                                    triggerMode: TooltipTriggerMode.tap,
                                    child: Text('ER'),
                                  ),
                                  numeric: true,
                                ),
                                const DataColumn(
                                  label: Tooltip(
                                    message: 'Total de Palpites',
                                    triggerMode: TooltipTriggerMode.tap,
                                    child: Text('TOT'),
                                  ),
                                  numeric: true,
                                ),
                              ],
                              rows: rankings.map((member) {
                                final isCurrentUser = member.id == currentUserId;
                                return DataRow(
                                  onSelectChanged: isCurrentUser
                                      ? null
                                      : (_) {
                                          context.go(
                                            '/ligas/$leagueId/usuario/${member.id}',
                                          );
                                        },
                                  color: isCurrentUser
                                      ? MaterialStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.3),
                                        )
                                      : null,
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [Text('${member.rank}')],
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: nameWidth,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: ClipOval(
                                                child: member.photoUrl != null
                                                    ? AppNetworkImage(
                                                        url: member.photoUrl!,
                                                        fit: BoxFit.cover,
                                                        errorWidget: CircleAvatar(
                                                          radius: 10,
                                                          child: Text(
                                                            member.name.isNotEmpty
                                                                ? member.name[0]
                                                                : '?',
                                                            style: const TextStyle(fontSize: 10),
                                                          ),
                                                        ),
                                                      )
                                                    : CircleAvatar(
                                                        radius: 10,
                                                        child: Text(
                                                          member.name.isNotEmpty
                                                              ? member.name[0].toUpperCase()
                                                              : '?',
                                                          style: const TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                member.name,
                                                style: TextStyle(
                                                  fontWeight: isCurrentUser
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!isLeagueActive &&
                                                member.rank >= 1 &&
                                                member.rank <= 3) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                member.rank == 1
                                                    ? '🏆'
                                                    : member.rank == 2
                                                    ? '🥈'
                                                    : '🥉',
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${member.points}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text('${member.stats.exactScore}')),
                                    DataCell(Text('${member.stats.winnerDiff}')),
                                    DataCell(Text('${member.stats.winnerGoal}')),
                                    DataCell(Text('${member.stats.winnerOnly}')),
                                    DataCell(Text('${member.stats.errors}')),
                                    DataCell(Text('${member.stats.total}')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isRankingLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: LoadingWidget(size: 30)),
            ),
        ],
      ),
    );
  }
}