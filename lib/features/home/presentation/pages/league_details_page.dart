import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/auth/data/repositories/auth_repository.dart';
import 'package:football_predictions/features/home/data/models/league_details_model.dart';
import 'package:football_predictions/features/home/data/models/league_ranking_model.dart';
import 'package:football_predictions/features/home/data/repositories/leagues_repository.dart';
import 'package:football_predictions/features/home/data/models/rule_model.dart';
import 'package:football_predictions/features/matches/data/models/match_model.dart';
import 'package:football_predictions/features/matches/data/repositories/matches_repository.dart';
import 'package:football_predictions/features/predictions/data/models/prediction_model.dart';
import 'package:football_predictions/features/predictions/data/repositories/predictions_repository.dart';
import 'package:football_predictions/features/predictions/presentation/pages/prediction_page.dart';
import 'package:football_predictions/features/home/presentation/pages/edit_league_page.dart';
import '../widgets/glass_card.dart';
import 'package:provider/provider.dart';

class LeagueDetailsPage extends StatefulWidget {
  final String leagueId;

  const LeagueDetailsPage({super.key, required this.leagueId});

  @override
  State<LeagueDetailsPage> createState() => _LeagueDetailsPageState();
}

class _LeagueDetailsPageState extends State<LeagueDetailsPage> {
  late Future<LeagueDetailsModel> _detailsFuture;
  late Future<List<dynamic>> _rankingDataFuture;
  late Future<LeagueRulesModel> _rulesFuture;
  late Future<String> _userIdFuture;

  @override
  void initState() {
    super.initState();
    final repo = context.read<LeaguesRepository>();
    final authRepo = context.read<AuthRepository>();
    _detailsFuture = repo.getLeagueDetails(widget.leagueId);
    _userIdFuture = authRepo.getUserId();
    _rankingDataFuture = Future.wait([
      repo.getLeagueRanking(widget.leagueId),
      authRepo.getUserId(),
    ]);
    _rulesFuture = repo.getRules();
  }

  Future<void> _refreshData() async {
    final repo = context.read<LeaguesRepository>();
    final authRepo = context.read<AuthRepository>();
    setState(() {
      _detailsFuture = repo.getLeagueDetails(widget.leagueId);
      _rankingDataFuture = Future.wait([
        repo.getLeagueRanking(widget.leagueId),
        authRepo.getUserId(),
      ]);
      _rulesFuture = repo.getRules();
    });
    // Aguarda o carregamento para parar o indicador de refresh
    await Future.wait([_detailsFuture, _rankingDataFuture, _rulesFuture]);
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
        title: const Text('Detalhes da Liga'),
        backgroundColor: const Color(0xFF1B5E20), // Verde escuro
        foregroundColor: Colors.white,
        actions: [
          FutureBuilder(
            future: Future.wait([_detailsFuture, _userIdFuture]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final league = snapshot.data![0] as LeagueDetailsModel;
              final userId = snapshot.data![1] as String;

              // Só mostra o botão se o usuário for o dono da liga
              if (league.owner.id == userId) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar Liga',
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            EditLeaguePage(leagueId: league.id),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        _detailsFuture = context
                            .read<LeaguesRepository>()
                            .getLeagueDetails(widget.leagueId);
                      });
                    }
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background do campo de futebol
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.fill,
              //color: Colors.black.withOpacity(0.6), // Escurece a imagem
              colorBlendMode: BlendMode.darken,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Erro ao carregar imagem de fundo: $error');
                // Fallback para um gradiente verde caso a imagem falhe
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
          SafeArea(
            top: false,
            child: FutureBuilder<LeagueDetailsModel>(
              future: _detailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar detalhes: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (!snapshot.hasData) return const SizedBox();

                final league = snapshot.data!;

                return DefaultTabController(
                  length: 5,
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    notificationPredicate: (notification) {
                      return notification.depth == 2;
                    },
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          SliverToBoxAdapter(child: _buildLeagueHeader(league)),
                          SliverPersistentHeader(
                            delegate: _SliverAppBarDelegate(
                              TabBar(
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white70,
                                indicatorColor: Colors.white,
                                isScrollable: true,
                                tabs: const [
                                  Tab(text: 'Ranking'),
                                  Tab(text: 'Palpitar'),
                                  Tab(text: 'Ativos'),
                                  Tab(text: 'Histórico'),
                                  Tab(text: 'Regras'),
                                ],
                              ),
                            ),
                            pinned: true,
                          ),
                        ];
                      },
                      body: TabBarView(
                        children: [
                          _buildRankingTab(),
                          _buildMatchesTab(league.competition.id),
                          _buildActivePredictionsTab(league.competition.id),
                          _buildHistoryPredictionsTab(league.competition.id),
                          _buildRulesTab(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueHeader(LeagueDetailsModel league) {
    return GlassCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: league.avatar != null
                ? NetworkImage(league.avatar!)
                : null,
            child: league.avatar == null
                ? Text(
                    league.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            league.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(league.description, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                'Competição',
                league.competition.name,
                imageUrl: league.competition.emblem,
              ),
              _buildInfoItem('Criador', league.owner.name),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: league.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Código copiado para a área de transferência!'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Código: ${league.code}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.copy,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {String? imageUrl}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (imageUrl != null) ...[
              AppNetworkImage(
                url: imageUrl,
                width: 20,
                height: 20,
                errorWidget: const Icon(Icons.sports_soccer, size: 20),
              ),
              const SizedBox(width: 8),
            ],
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildScrollablePlaceholder(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }

  Widget _buildRankingTab() {
    return FutureBuilder<List<dynamic>>(
      future: _rankingDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        if (snapshot.hasError) {
          return _buildScrollablePlaceholder(
            Text('Erro ao carregar ranking: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return _buildScrollablePlaceholder(
            const Text('Nenhum participante encontrado.'),
          );
        }

        final ranking = snapshot.data![0] as List<LeagueRankingModel>;
        final currentUserId = snapshot.data![1] as String;

        if (ranking.isEmpty) {
          return _buildScrollablePlaceholder(
            const Text('Nenhum participante encontrado.'),
          );
        }

        return ListView(
          key: const PageStorageKey('ranking'),
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: GlassCard(
                margin: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowHeight: 40,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 48,
                    columns: const [
                      DataColumn(label: Text('#'), numeric: true),
                      DataColumn(label: Text('Nome')),
                      DataColumn(label: Text('Pts'), numeric: true),
                      DataColumn(
                        label: Tooltip(
                          message: 'Placar Exato',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Text('PE'),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Tooltip(
                          message: 'Vencedor + Saldo',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Text('VS'),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Tooltip(
                          message: 'Vencedor + Gols',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Text('VG'),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Tooltip(
                          message: 'Apenas Vencedor',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Text('AV'),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Tooltip(
                          message: 'Erros',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Text('ER'),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Tooltip(
                          message: 'Total de Palpites',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Text('TOT'),
                        ),
                        numeric: true,
                      ),
                    ],
                    rows: ranking.map((member) {
                      final isCurrentUser = member.id == currentUserId;
                      return DataRow(
                        color: isCurrentUser
                            ? MaterialStateProperty.all(
                                Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                              )
                            : null,
                        cells: [
                          DataCell(Text('${member.rank}')),
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundImage: member.photoUrl != null
                                      ? NetworkImage(member.photoUrl!)
                                      : null,
                                  child: member.photoUrl == null
                                      ? Text(
                                          member.name.isNotEmpty
                                              ? member.name[0]
                                              : '?',
                                          style: const TextStyle(fontSize: 10),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(member.name),
                              ],
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchesTab(int competitionId) {
    return FutureBuilder<List<MatchModel>>(
      future: context.read<MatchesRepository>().getMatchesPredictions(
        competitionId: competitionId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        } else if (snapshot.hasError) {
          return _buildScrollablePlaceholder(
            Text(
              'Erro ao carregar partidas:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildScrollablePlaceholder(
            const Text('Nenhuma partida disponível.'),
          );
        }

        final matches = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PredictionPage(
                        match: match,
                        leagueId: widget.leagueId,
                      ),
                    ),
                  );
                  if (result == true) {
                    setState(() {});
                  }
                },
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
                      child: Text(
                        '${match.homeScore ?? '-'} x ${match.awayScore ?? '-'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                subtitle: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: Text(_translateStatus(match.status))),
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
    );
  }

  Widget _buildActivePredictionsTab(int competitionId) {
    return _buildPredictionsList(
      context.read<PredictionsRepository>().getUpcomingPredictions(
        competitionId: competitionId,
      ),
    );
  }

  Widget _buildHistoryPredictionsTab(int competitionId) {
    return _buildPredictionsList(
      context.read<PredictionsRepository>().getPredictions(
        competitionId: competitionId,
      ),
    );
  }

  Widget _buildPredictionsList(Future<List<PredictionModel>> future) {
    return FutureBuilder<List<PredictionModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        } else if (snapshot.hasError) {
          return _buildScrollablePlaceholder(
            Text(
              'Erro ao carregar palpites:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildScrollablePlaceholder(
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

            return GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                onTap: isEditable
                    ? () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PredictionPage(
                              match: match,
                              leagueId: widget.leagueId,
                              predictionId: prediction.id,
                            ),
                          ),
                        );
                        if (result == true) {
                          setState(() {});
                        }
                      }
                    : null,
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
                            const Text(
                              'Placar',
                              style: TextStyle(fontSize: 10),
                            ),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pontos ganhos: ${prediction.pointsEarned}',
                              style: TextStyle(
                                color: prediction.pointsEarned == 0
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Icon(
                                prediction.pointsEarned == 0
                                    ? Icons.cancel
                                    : Icons.check_circle,
                                size: 16,
                                color: prediction.pointsEarned == 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRulesTab() {
    return FutureBuilder<LeagueRulesModel>(
      future: _rulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        } else if (snapshot.hasError) {
          return _buildScrollablePlaceholder(
            Text(
              'Erro ao carregar regras:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData) {
          return _buildScrollablePlaceholder(
            const Text('Nenhuma regra encontrada.'),
          );
        }

        final rules = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(8),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (rules.scoring.isNotEmpty)
              GlassCard(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 Sistema de Pontuação',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ganhe pontos acertando os resultados dos jogos! Veja como funciona:',
                    ),
                    const SizedBox(height: 16),
                    ...rules.scoring.map(
                      (rule) => Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              child: Text('${rule.points}'),
                            ),
                            title: Text(
                              rule.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rule.description),
                                const SizedBox(height: 4),
                                Text(
                                  'Exemplo: ${rule.example}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (rule != rules.scoring.last) const Divider(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (rules.tieBreakers.isNotEmpty)
              GlassCard(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Critérios de Desempate',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ...rules.tieBreakers.map(
                      (tb) => Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondary,
                              child: Text('${tb.order}'),
                            ),
                            title: Text(
                              tb.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(tb.description),
                          ),
                          if (tb != rules.tieBreakers.last) const Divider(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF1B5E20).withValues(alpha: 0.95),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
