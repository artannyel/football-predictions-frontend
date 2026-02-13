import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/blinking_live_indicator.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/auth/data/repositories/auth_repository.dart';
import 'package:football_predictions/features/home/data/models/league_details_model.dart';
import 'package:football_predictions/features/home/data/models/league_ranking_model.dart';
import 'package:football_predictions/features/home/data/repositories/leagues_repository.dart';
import 'package:football_predictions/features/home/data/models/rule_model.dart';
import 'package:football_predictions/features/matches/data/models/match_model.dart';
import 'package:football_predictions/features/predictions/data/models/prediction_model.dart';
import 'package:football_predictions/features/predictions/data/repositories/predictions_repository.dart';
import 'package:football_predictions/features/home/presentation/pages/edit_league_page.dart';
import 'package:go_router/go_router.dart';
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
  late Future<LeagueRulesModel> _rulesFuture;
  late Future<String> _userIdFuture;

  // Ranking state
  final List<LeagueRankingModel> _rankings = [];
  int _rankingPage = 1;
  int _rankingLastPage = 1;
  bool _isRankingLoading = false;
  bool _isSilentRankingLoading = false;
  String? _rankingError;
  String? _currentUserId;

  // History Predictions state
  final List<PredictionModel> _historyPredictions = [];
  int _historyPage = 1;
  int _historyLastPage = 1;
  bool _isHistoryLoading = false;
  bool _isSilentHistoryLoading = false;
  String? _historyError;

  late ConfettiController _confettiController;
  late ConfettiController _fireworksController;
  bool _confettiPlayed = false;
  StreamSubscription? _firestoreSubscription;

  @override
  void initState() {
    super.initState();
    final repo = context.read<LeaguesRepository>();
    final authRepo = context.read<AuthRepository>();
    _detailsFuture = repo.getLeagueDetails(widget.leagueId);
    _userIdFuture = authRepo.getUser().then((u) => u.id);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _fireworksController = ConfettiController(
      duration: const Duration(seconds: 10),
    );

    // Carrega ranking inicial e usuário
    _loadRanking();
    _loadHistoryPredictions();
    _userIdFuture.then((id) {
      if (mounted) setState(() => _currentUserId = id);
    });

    _rulesFuture = repo.getRules();
    
    // Configura o listener do Firestore assim que tivermos os detalhes da liga (e o ID da competição)
    _detailsFuture.then((league) {
      if (mounted) {
        _setupFirestoreListener(league.competition.id);
      }
    });
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _confettiController.dispose();
    _fireworksController.dispose();
    super.dispose();
  }

  Future<void> _loadRanking({bool refresh = false, bool silent = false}) async {
    if (_isRankingLoading || _isSilentRankingLoading) return;

    if (refresh) {
      _rankingPage = 1;
      _rankingLastPage = 1;
      if (!silent) {
        _rankings.clear();
        _rankingError = null;
      }
    } else if (_rankingPage > _rankingLastPage) {
      return;
    }

    if (silent) {
      _isSilentRankingLoading = true;
    } else {
      setState(() => _isRankingLoading = true);
    }

    try {
      final repo = context.read<LeaguesRepository>();
      final result = await repo.getLeagueRanking(
        widget.leagueId,
        page: _rankingPage,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _rankings.clear();
            _rankingError = null;
          }
          _rankings.addAll(result.rankings);
          _rankingLastPage = result.lastPage;
          _rankingPage++;
          if (silent) {
            _isSilentRankingLoading = false;
          } else {
            _isRankingLoading = false;
          }
        });
        _checkConfetti();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) {
            _rankingError = e.toString().replaceAll('Exception: ', '');
            _isRankingLoading = false;
          } else {
            _isSilentRankingLoading = false;
          }
        });
      }
    }
  }

  Future<void> _checkConfetti() async {
    if (_confettiPlayed) return;

    try {
      final results = await Future.wait([_detailsFuture, _userIdFuture]);
      if (!mounted) return;

      final league = results[0] as LeagueDetailsModel;
      final userId = results[1] as String;

      if (!league.isActive && _rankings.isNotEmpty) {
        final userIndex = _rankings.indexWhere((r) => r.id == userId);
        if (userIndex != -1) {
          final rank = _rankings[userIndex].rank;
          if (rank >= 1 && rank <= 3) {
            _confettiPlayed = true;
            _confettiController.play();
            if (rank == 1) {
              _fireworksController.play();
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadHistoryPredictions({bool refresh = false, bool silent = false}) async {
    if (_isHistoryLoading || _isSilentHistoryLoading) return;

    if (refresh) {
      _historyPage = 1;
      _historyLastPage = 1;
      if (!silent) {
        _historyPredictions.clear();
        _historyError = null;
      }
    } else if (_historyPage > _historyLastPage) {
      return;
    }

    if (silent) {
      _isSilentHistoryLoading = true;
    } else {
      setState(() => _isHistoryLoading = true);
    }

    try {
      final repo = context.read<PredictionsRepository>();
      final result = await repo.getPredictions(
        leagueId: widget.leagueId,
        page: _historyPage,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _historyPredictions.clear();
            _historyError = null;
          }
          _historyPredictions.addAll(result.predictions);
          _historyLastPage = result.lastPage;
          _historyPage++;
          if (silent) {
            _isSilentHistoryLoading = false;
          } else {
            _isHistoryLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) {
            _historyError = e.toString().replaceAll('Exception: ', '');
            _isHistoryLoading = false;
          } else {
            _isSilentHistoryLoading = false;
          }
        });
      }
    }
  }

  void _setupFirestoreListener(int competitionId) {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('competition_updates')
        .doc(competitionId.toString())
        .snapshots()
        .listen((snapshot) async {
      // Random delay de 0 a 10 segundos (0 a 10000 ms) para evitar thundering herd
      final delay = Random().nextInt(10000);
      await Future.delayed(Duration(milliseconds: delay));

      if (mounted) {
        _loadRanking(refresh: true, silent: true);
        _loadHistoryPredictions(refresh: true, silent: true);
        // O setState fará o rebuild, atualizando também o FutureBuilder dos palpites ativos
        setState(() {});
      }
    });
  }

  Future<void> _refreshData() async {
    final repo = context.read<LeaguesRepository>();
    setState(() {
      _detailsFuture = repo.getLeagueDetails(widget.leagueId);
      _rulesFuture = repo.getRules();
    });
    // Aguarda o carregamento para parar o indicador de refresh
    await Future.wait([
      _detailsFuture,
      _loadRanking(refresh: true),
      _loadHistoryPredictions(refresh: true),
      _rulesFuture,
    ]);
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

  void _onBackPage(BuildContext context) {
    context.go('/ligas');
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (canPop, _) {
        _onBackPage(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes da Liga'),
          leading: IconButton(
            onPressed: () => _onBackPage(context),
            icon: Icon(Icons.arrow_back_rounded),
          ),
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
                    if (snapshot.error.toString().contains('403')) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 64,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Acesso Negado',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Você não tem permissão para visualizar esta liga.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () => context.go('/ligas'),
                                    child: const Text(
                                      'VOLTAR PARA MINHAS LIGAS',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Text(
                        'Erro ao carregar detalhes: ${snapshot.error.toString().replaceAll('Exception: ', '')}',
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
                            SliverToBoxAdapter(
                              child: _buildLeagueHeader(league),
                            ),
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
                            _buildRankingTab(league.isActive),
                            _buildMatchesTab(league.id),
                            _buildActivePredictionsTab(league.id),
                            _buildHistoryPredictionsTab(league.id),
                            _buildRulesTab(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.amber,
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _fireworksController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.amber,
                ],
                createParticlePath: drawStar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueHeader(LeagueDetailsModel league) {
    LeagueRankingModel? champion;
    LeagueRankingModel? viceChampion;
    LeagueRankingModel? thirdPlace;

    if (!league.isActive && _rankings.isNotEmpty) {
      try {
        champion = _rankings.firstWhere((r) => r.rank == 1);
      } catch (_) {}
      try {
        viceChampion = _rankings.firstWhere((r) => r.rank == 2);
      } catch (_) {}
      try {
        thirdPlace = _rankings.firstWhere((r) => r.rank == 3);
      } catch (_) {}
    }

    return GlassCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!league.isActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    "LIGA FINALIZADA",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (champion != null) ...[
              const Text(
                "🏆 CAMPEÃO 🏆",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: champion.photoUrl != null
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.9,
                            ),
                            insetPadding: EdgeInsets.zero,
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  child: Center(
                                    child: AppNetworkImage(
                                      url: champion!.photoUrl!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: SafeArea(
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.white),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    : null,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: ClipOval(
                    child: champion.photoUrl != null
                        ? AppNetworkImage(
                            url: champion.photoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: CircleAvatar(
                              radius: 60,
                              child: Text(
                                champion.name.isNotEmpty
                                    ? champion.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 60,
                            child: Text(
                              champion.name.isNotEmpty
                                  ? champion.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                champion.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '${champion.points} pts',
                style: const TextStyle(fontSize: 14),
              ),
              if (viceChampion != null || thirdPlace != null) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (viceChampion != null)
                      Expanded(child: _buildPodiumItem(viceChampion, 2)),
                    if (thirdPlace != null)
                      Expanded(child: _buildPodiumItem(thirdPlace, 3)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
            ],
          ],
          SizedBox(
            width: 80,
            height: 80,
            child: ClipOval(
              child: league.avatar != null
                  ? AppNetworkImage(
                      url: league.avatar!,
                      fit: BoxFit.cover,
                      errorWidget: CircleAvatar(
                        radius: 40,
                        child: Text(
                          league.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 40,
                      child: Text(
                        league.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
            ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Competição',
                  league.competition.name,
                  imageUrl: league.competition.emblem,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Criador',
                  league.owner.name,
                  imageUrl: league.owner.photoUrl,
                ),
              ),
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

  Widget _buildPodiumItem(LeagueRankingModel member, int rank) {
    final color = rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32);
    final label = rank == 2 ? "🥈 Vice-Campeão" : "🥉 3º Lugar";

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: member.photoUrl != null
              ? () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.black.withValues(alpha: 0.9),
                      insetPadding: EdgeInsets.zero,
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            child: Center(
                              child: AppNetworkImage(
                                url: member.photoUrl!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: SafeArea(
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () =>
                                    Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              : null,
          child: SizedBox(
            width: 80,
            height: 80,
            child: ClipOval(
              child: member.photoUrl != null
                  ? AppNetworkImage(
                      url: member.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: CircleAvatar(
                        radius: 40,
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 40,
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          member.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${member.points} pts',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {String? imageUrl}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl != null) ...[
              ClipOval(
                clipBehavior: Clip.antiAlias,
                child: AppNetworkImage(
                  url: imageUrl,
                  width: 20,
                  height: 20,
                  errorWidget: const Icon(Icons.sports_soccer, size: 20),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
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

  Widget _buildRankingTab(bool isLeagueActive) {
    if (_rankingError != null && _rankings.isEmpty) {
      return _buildScrollablePlaceholder(
        Text('Erro ao carregar ranking: $_rankingError'),
      );
    }

    if (_rankings.isEmpty && _isRankingLoading) {
      return const LoadingWidget();
    }

    if (_rankings.isEmpty) {
      return _buildScrollablePlaceholder(
        const Text('Nenhum participante encontrado.'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isRankingLoading &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _loadRanking();
        }
        return false;
      },
      child: ListView(
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
                  showCheckboxColumn: false,
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
                  rows: _rankings.map((member) {
                    final isCurrentUser = member.id == _currentUserId;
                    return DataRow(
                      onSelectChanged: isCurrentUser
                          ? null
                          : (_) {
                              context.go(
                                '/liga/${widget.leagueId}/usuario/${member.id}',
                              );
                            },
                      color: isCurrentUser
                          ? MaterialStateProperty.all(
                              Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.3),
                            )
                          : null,
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${member.rank}'),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
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
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        )
                                      : CircleAvatar(
                                          radius: 10,
                                          child: Text(
                                            member.name.isNotEmpty
                                                ? member.name[0]
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                member.name,
                                style: TextStyle(
                                  fontWeight: isCurrentUser
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (!isLeagueActive &&
                                  member.rank >= 1 &&
                                  member.rank <= 3) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.emoji_events,
                                  size: 20,
                                  color: member.rank == 1
                                      ? const Color(0xFFFFD700) // Ouro
                                      : member.rank == 2
                                      ? const Color(0xFFC0C0C0) // Prata
                                      : const Color(0xFFCD7F32), // Bronze
                                ),
                              ],
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            '${member.points}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
          if (_isRankingLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: LoadingWidget(size: 30)),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(String leagueId) {
    return FutureBuilder<List<MatchModel>>(
      future: context.read<LeaguesRepository>().getMatchesPredictions(
        leagueId: leagueId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        } else if (snapshot.hasError) {
          return _buildScrollablePlaceholder(
            Text(
              'Erro ao carregar partidas:\n${snapshot.error.toString().replaceAll('Exception: ', '')}',
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
                  final result = await context.pushNamed(
                    'Prediction',
                    pathParameters: {
                      'id': widget.leagueId,
                      'matchId': match.id.toString(),
                    },
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
                    Center(
                      child: match.status == 'IN_PLAY'
                          ? const BlinkingLiveIndicator()
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
    );
  }

  Widget _buildActivePredictionsTab(String leagueId) {
    return _buildPredictionsList(
      context.read<PredictionsRepository>().getUpcomingPredictions(
        leagueId: leagueId,
      ),
    );
  }

  Widget _buildHistoryPredictionsTab(String leagueId) {
    if (_historyError != null && _historyPredictions.isEmpty) {
      return _buildScrollablePlaceholder(
        Text(
          'Erro ao carregar histórico:\n$_historyError',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_historyPredictions.isEmpty && _isHistoryLoading) {
      return const LoadingWidget();
    }

    if (_historyPredictions.isEmpty) {
      return _buildScrollablePlaceholder(
        const Text('Nenhum palpite encontrado.'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isHistoryLoading &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _loadHistoryPredictions();
        }
        return false;
      },
      child: ListView.builder(
        key: const PageStorageKey('history'),
        padding: const EdgeInsets.all(8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _historyPredictions.length + (_isHistoryLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _historyPredictions.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: LoadingWidget(size: 30)),
            );
          }

          final prediction = _historyPredictions[index];
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
                    match.status == 'IN_PLAY'
                        ? const BlinkingLiveIndicator()
                        : Text(_translateStatus(match.status)),
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
                          Icon(
                            prediction.pointsEarned == 0
                                ? Icons.cancel
                                : Icons.check_circle,
                            size: 16,
                            color: prediction.pointsEarned == 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ],
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

  Widget _buildPredictionsList(Future<List<PredictionModel>> future) {
    return FutureBuilder<List<PredictionModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        } else if (snapshot.hasError) {
          return _buildScrollablePlaceholder(
            Text(
              'Erro ao carregar palpites:\n${snapshot.error.toString().replaceAll('Exception: ', '')}',
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
                        final result = await context.pushNamed(
                          'Prediction',
                          pathParameters: {
                            'id': widget.leagueId,
                            'matchId': match.id.toString(),
                          },
                          queryParameters: {
                            'predictionId': prediction.id.toString(),
                          },
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
                      match.status == 'IN_PLAY'
                          ? const BlinkingLiveIndicator()
                          : Text(_translateStatus(match.status)),
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
              'Erro ao carregar regras:\n${snapshot.error.toString().replaceAll('Exception: ', '')}',
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
