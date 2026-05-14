import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/core/presentation/widgets/web_constrained_box.dart';
import 'package:football_predictions/features/auth/data/repositories/auth_repository.dart';
import 'package:football_predictions/features/home/data/models/league_details_model.dart';
import 'package:football_predictions/features/home/data/models/league_ranking_model.dart';
import 'package:football_predictions/features/home/data/models/league_feed_model.dart';
import 'package:football_predictions/features/home/data/repositories/leagues_repository.dart';
import 'package:football_predictions/features/home/data/models/rule_model.dart';
import 'package:football_predictions/features/home/presentation/pages/tabs/feed_tab.dart';
import 'package:football_predictions/features/home/presentation/pages/tabs/ranking_tab.dart';
import 'package:football_predictions/features/home/presentation/pages/tabs/rules_tab.dart';
import 'package:football_predictions/features/home/presentation/pages/tabs/matches_tab.dart';
import 'package:football_predictions/features/home/presentation/pages/tabs/active_predictions_tab.dart';
import 'package:football_predictions/features/home/presentation/pages/tabs/history_predictions_tab.dart';
import 'package:football_predictions/features/predictions/data/models/prediction_model.dart';
import 'package:football_predictions/features/predictions/data/repositories/predictions_repository.dart';
import 'package:football_predictions/features/home/presentation/pages/edit_league_page.dart';
import 'package:go_router/go_router.dart';
import '../widgets/glass_card.dart';
import '../widgets/league_header_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeagueDetailsPage extends StatefulWidget {
  final String leagueId;

  const LeagueDetailsPage({super.key, required this.leagueId});

  @override
  State<LeagueDetailsPage> createState() => _LeagueDetailsPageState();
}

class _LeagueDetailsPageState extends State<LeagueDetailsPage>
    with TickerProviderStateMixin {
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

  // Feed state
  final List<LeagueFeedModel> _feedItems = [];
  int _feedPage = 1;
  int _feedLastPage = 1;
  bool _isFeedLoading = false;
  String? _feedError;

  late ConfettiController _confettiController;
  late ConfettiController _fireworksController;
  bool _confettiPlayed = false;
  late TabController _tabController;
  StreamSubscription? _firestoreSubscription;
  DateTime? _lastReadTime;

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
    _tabController = TabController(length: 6, vsync: this);
    _loadLastReadTime();

    // Carrega ranking inicial e usuário
    _loadRanking();
    _loadHistoryPredictions();
    _loadFeed();
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
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLastReadTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_read_${widget.leagueId}');
    if (timestamp != null && mounted) {
      setState(() {
        _lastReadTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      });
    }
  }

  Future<void> _updateLastReadTime() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_read_${widget.leagueId}',
      now.millisecondsSinceEpoch,
    );
    if (mounted) {
      setState(() {
        _lastReadTime = now;
      });
    }
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

  Future<void> _loadHistoryPredictions({
    bool refresh = false,
    bool silent = false,
  }) async {
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

  Future<void> _loadFeed({bool refresh = false}) async {
    if (_isFeedLoading) return;

    if (refresh) {
      _feedPage = 1;
      _feedLastPage = 1;
      _feedItems.clear();
      _feedError = null;
    } else if (_feedPage > _feedLastPage) {
      return;
    }

    setState(() => _isFeedLoading = true);

    try {
      final repo = context.read<LeaguesRepository>();
      final result = await repo.getLeagueFeed(widget.leagueId, page: _feedPage);

      if (mounted) {
        setState(() {
          _feedItems.addAll(result.feed);
          _feedLastPage = result.lastPage;
          _feedPage++;
          _isFeedLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedError = e.toString().replaceAll('Exception: ', '');
          _isFeedLoading = false;
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
          final delay = math.Random().nextInt(10000);
          await Future.delayed(Duration(milliseconds: delay));

          if (mounted) {
            _loadRanking(refresh: true, silent: true);
            _loadHistoryPredictions(refresh: true, silent: true);
            _loadFeed(refresh: true);
            // O setState fará o rebuild, atualizando também o FutureBuilder dos palpites ativos
            setState(() {});
          }
        });
  }

  void _refreshLeagueDetails() {
    if (mounted) {
      setState(() {
        _detailsFuture = context.read<LeaguesRepository>().getLeagueDetails(
          widget.leagueId,
        );
      });
    }
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
      _loadFeed(refresh: true),
      _rulesFuture,
    ]);
  }

  void _onBackPage(BuildContext context) {
    context.go('/ligas');
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (math.pi / 180.0);

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
      path.lineTo(
        halfWidth + externalRadius * math.cos(step),
        halfWidth + externalRadius * math.sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * math.cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * math.sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
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
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leagues')
                  .doc(widget.leagueId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                bool hasUnread = false;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final doc = snapshot.data!.docs.first;
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final userId = data['userId'] as String?;

                  // Verifica se a mensagem é nova e não é do próprio usuário
                  if (createdAt != null && userId != _currentUserId) {
                    if (_lastReadTime == null ||
                        createdAt.isAfter(_lastReadTime!)) {
                      hasUnread = true;
                    }
                  }
                }

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      tooltip: 'Chat da Liga',
                      onPressed: () {
                        _updateLastReadTime();
                        context.go('/ligas/${widget.leagueId}/chat');
                      },
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
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

                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    notificationPredicate: (notification) {
                      return notification.depth == 2;
                    },
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          SliverToBoxAdapter(
                            child: LeagueHeaderWidget(
                              league: league,
                              rankings: _rankings,
                            ),
                          ),
                          SliverPersistentHeader(
                            delegate: _SliverAppBarDelegate(
                              TabBar(
                                controller: _tabController,
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white70,
                                indicatorColor: Colors.white,
                                isScrollable: true,
                                tabs: const [
                                  Tab(text: 'Ranking'),
                                  Tab(text: 'Palpitar'),
                                  Tab(text: 'Ativos'),
                                  Tab(text: 'Histórico'),
                                  Tab(text: 'Feed'),
                                  Tab(text: 'Regras'),
                                ],
                              ),
                            ),
                            pinned: true,
                          ),
                        ];
                      },
                      body: TabBarView(
                        controller: _tabController,
                        children: [
                          RankingTab(
                            rankingError: _rankingError,
                            rankings: _rankings,
                            isRankingLoading: _isRankingLoading,
                            currentUserId: _currentUserId,
                            isLeagueActive: league.isActive,
                            onLoadMore: () => _loadRanking(),
                            leagueId: widget.leagueId,
                          ),
                          MatchesTab(
                            leagueId: league.id,
                            onRefreshDetails: _refreshLeagueDetails,
                          ),
                          ActivePredictionsTab(
                            leagueId: league.id,
                            onRefreshDetails: _refreshLeagueDetails,
                          ),
                          HistoryPredictionsTab(
                            leagueId: league.id,
                            historyError: _historyError,
                            historyPredictions: _historyPredictions,
                            isHistoryLoading: _isHistoryLoading,
                            onLoadMore: () => _loadHistoryPredictions(),
                            onRefreshDetails: () {
                              _loadHistoryPredictions(refresh: true);
                              _refreshLeagueDetails();
                            },
                          ),
                          FeedTab(
                            feedError: _feedError,
                            feedItems: _feedItems,
                            isFeedLoading: _isFeedLoading,
                            onLoadMore: () => _loadFeed(),
                            leagueId: widget.leagueId,
                          ),
                          RulesTab(rulesFuture: _rulesFuture),
                        ],
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
      child: Center(child: WebConstrainedBox(child: _tabBar)),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
