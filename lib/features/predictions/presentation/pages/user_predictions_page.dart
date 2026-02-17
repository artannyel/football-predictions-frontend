import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:football_predictions/core/auth/auth_notifier.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/blinking_live_indicator.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/auth/data/models/user_model.dart';
import 'package:football_predictions/features/home/data/models/league_ranking_model.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:football_predictions/core/presentation/widgets/radar_chart.dart';
import 'package:football_predictions/features/predictions/data/models/prediction_model.dart';
import 'package:football_predictions/features/predictions/data/repositories/predictions_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UserPredictionsPage extends StatefulWidget {
  final String userId;
  final String leagueId;

  const UserPredictionsPage({
    super.key,
    required this.userId,
    required this.leagueId,
  });

  @override
  State<UserPredictionsPage> createState() => _UserPredictionsPageState();
}

class _UserPredictionsPageState extends State<UserPredictionsPage> {
  final List<({PredictionModel user, PredictionModel? me})> _predictions = [];
  int _page = 1;
  int _lastPage = 1;
  bool _isLoading = false;
  String? _error;
  RankingStatsModel? _userStats;
  UserModel? _userHistory;
  RankingStatsModel? _meStats;
  UserModel? _meHistory;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && _page > _lastPage) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _page = 1;
        _lastPage = 1;
        _error = null;
      }
    });

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
          if (refresh) {
            _predictions.clear();
          }
          _predictions.addAll(result.predictions);
          _lastPage = result.lastPage;
          if (_page == 1) {
            _userStats = result.userStats;
            _meStats = result.meStats;
          }
          _userHistory = result.userModel;
          _meHistory = result.meModel;
          _page++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
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

  String _translateStage(String stage) {
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

  String _formatMatchday(String stage, int matchday) {
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

  void _navigateToProfile(UserModel? user) {
    if (user == null) return;
    final currentUser = context.read<AuthNotifier>().backendUser;
    if (currentUser != null && currentUser.id == user.id) {
      context.pushNamed('Profile');
    } else {
      context.pushNamed('UserProfile', pathParameters: {'userId': user.id});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userHistory != null
              ? 'Palpites de ${_userHistory!.name}'
              : 'Palpites',
        ),
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
          SafeArea(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Se não tiver stats e estiver carregando (primeira carga), mostra loading tela cheia
    if (_userStats == null && _isLoading) {
      return const Center(child: LoadingWidget());
    }

    // Se não tiver stats e der erro (primeira carga), mostra erro tela cheia
    if (_userStats == null && _error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white)),
      );
    }

    final hasStats = _userStats != null;
    final hasPredictions = _predictions.isNotEmpty;

    // Calcula o número de itens
    int itemCount = 0;
    if (hasStats) itemCount++; // Header

    if (hasPredictions) {
      itemCount += _predictions.length;
      if (_isLoading && _page > 1) itemCount++; // Loader do scroll infinito
    } else {
      itemCount++; // Item de status (Vazio, Erro ou Loading) abaixo do header
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isLoading &&
            hasPredictions &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _loadPredictions();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _loadPredictions(refresh: true),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // 1. Header de Estatísticas
            if (hasStats && index == 0) {
              if (_meStats != null &&
                  _meHistory != null &&
                  _meHistory!.id != _userHistory!.id) {
                return _buildRadarComparison();
              }
              return _buildStatsHeader(_userStats!, _userHistory);
            }

            // Ajusta o índice considerando o header
            final contentIndex = hasStats ? index - 1 : index;

            // 2. Estado sem palpites (abaixo do header)
            if (!hasPredictions) {
              if (_isLoading) {
                return const Padding(
                  padding: EdgeInsets.only(top: 32.0),
                  child: Center(child: LoadingWidget()),
                );
              }
              if (_error != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
              return const Padding(
                padding: EdgeInsets.only(top: 32.0),
                child: Center(
                  child: Text(
                    'Nenhum palpite encontrado.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            // 3. Loader do Scroll Infinito
            if (contentIndex == _predictions.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: LoadingWidget(size: 30)),
              );
            }

            // 4. Item da Lista de Palpites
            final item = _predictions[contentIndex];
            final prediction = item.user;
            final myPrediction = item.me;
            final match = prediction.match;
            final isComparing =
                _userHistory != null &&
                _meHistory != null &&
                _userHistory!.id != _meHistory!.id;

            return TweenAnimationBuilder<double>(
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
                            '${_translateStage(match.stage)} • ${_formatMatchday(match.stage, match.matchday)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(match.utcDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    // Corpo: Times e Placar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mandante
                          Expanded(
                            child: Column(
                              children: [
                                _buildTeamLogo(match.homeTeamCrest),
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
                          // Placar e Status
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
                                        _translateStatus(match.status),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          // Visitante
                          Expanded(
                            child: Column(
                              children: [
                                _buildTeamLogo(match.awayTeamCrest),
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
                    // Footer: Palpites
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPredictionCard(
                              prediction,
                              _userHistory?.name.split(' ').first ?? 'Usuário',
                              Colors.cyanAccent,
                            ),
                          ),
                          if (isComparing) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPredictionCard(
                                myPrediction,
                                'Seu palpite',
                                Colors.amberAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRadarComparison() {
    final userStats = _userStats!;
    final meStats = _meStats!;

    // Dados para o gráfico
    final rawLabels = ['Exato', 'Saldo', 'Gols', 'Vencedor', 'Erros'];
    final userValues = [
      userStats.exactScore.toDouble(),
      userStats.winnerDiff.toDouble(),
      userStats.winnerGoal.toDouble(),
      userStats.winnerOnly.toDouble(),
      userStats.errors.toDouble(),
    ];
    final meValues = [
      meStats.exactScore.toDouble(),
      meStats.winnerDiff.toDouble(),
      meStats.winnerGoal.toDouble(),
      meStats.winnerOnly.toDouble(),
      meStats.errors.toDouble(),
    ];

    final labels = List<String>.generate(rawLabels.length, (i) {
      return '${rawLabels[i]}\n(${userValues[i].toInt()} / ${meValues[i].toInt()})';
    });

    // Calcula o valor máximo para escala
    double maxValue = 0;
    for (final v in [...userValues, ...meValues]) {
      if (v > maxValue) maxValue = v;
    }
    if (maxValue == 0) maxValue = 10; // Evita divisão por zero

    return Column(
      children: [
        GlassCard(
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Legenda (Placar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User (Left)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToProfile(_userHistory),
                        child: Row(
                          children: [
                            _buildAvatar(_userHistory, Colors.cyanAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _userHistory?.name.split(' ').first ??
                                    'Usuário',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Score (Center)
                    Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: (userStats.points ?? 0).toDouble(),
                              ),
                              duration: const Duration(seconds: 1),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.cyanAccent,
                                  ),
                                );
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                'x',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: (meStats.points ?? 0).toDouble(),
                              ),
                              duration: const Duration(seconds: 1),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.amberAccent,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const Text(
                          'pts',
                          style: TextStyle(fontSize: 10, color: Colors.white54),
                        ),
                      ],
                    ),
                    // Me (Right)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToProfile(_meHistory),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                _meHistory?.name.split(' ').first ?? 'Você',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildAvatar(_meHistory, Colors.amberAccent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Gráfico
              SizedBox(
                height: 220,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return RadarChart(
                      values1: userValues,
                      values2: meValues,
                      labels: labels,
                      maxValue: maxValue,
                      color1: Colors.cyanAccent,
                      color2: Colors.amberAccent,
                      animationValue: value,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Comparativo de desempenho',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Row(
            children: [
              Expanded(
                child: _buildComparisonStatCard(
                  'Total de Palpites',
                  userStats.total,
                  meStats.total,
                  Colors.cyanAccent,
                  Colors.amberAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildComparisonStatCard(
                  'Acurácia',
                  _calculateAccuracy(userStats),
                  _calculateAccuracy(meStats),
                  Colors.cyanAccent,
                  Colors.amberAccent,
                  isPercentage: true,
                  tooltip:
                      'Considera acerto qualquer palpite que pontuou.\nFórmula: ((Total - Erros) / Total) * 100',
                ),
              ),
            ],
          ),
        ),
        _buildBadgesComparison(_userHistory!.badges, _meHistory!.badges),
      ],
    );
  }

  double _calculateAccuracy(RankingStatsModel stats) {
    if (stats.total == 0) return 0.0;
    final hits = stats.total - stats.errors;
    return (hits / stats.total) * 100;
  }

  Widget _buildComparisonStatCard(
    String title,
    num val1,
    num val2,
    Color color1,
    Color color2, {
    bool isPercentage = false,
    String? tooltip,
  }) {
    String format(num v) =>
        isPercentage ? '${v.toStringAsFixed(0)}%' : '${v.toInt()}';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            if (tooltip != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: tooltip,
                    triggerMode: TooltipTriggerMode.tap,
                    child: const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              )
            else
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: val1.toDouble()),
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Text(
                          format(value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      height: 2,
                      width: 24,
                      color: color1,
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'vs',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ),
                Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: val2.toDouble()),
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Text(
                          format(value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      height: 2,
                      width: 24,
                      color: color2,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesComparison(
    List<BadgeModel> userBadges,
    List<BadgeModel> meBadges,
  ) {
    if (userBadges.isEmpty && meBadges.isEmpty) return const SizedBox();

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text(
            'Medalhas da Liga',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildBadgesList(userBadges, Colors.cyanAccent)),
              Container(
                width: 1,
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 32,
              ),
              Expanded(child: _buildBadgesList(meBadges, Colors.amberAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesList(List<BadgeModel> badges, Color color) {
    if (badges.isEmpty) {
      return const Center(
        child: Text('-', style: TextStyle(color: Colors.white30, fontSize: 24)),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: badges
          .asMap()
          .entries
          .map((entry) => _buildBadgeItem(entry.value, entry.key, color))
          .toList(),
    );
  }

  Widget _buildBadgeItem(BadgeModel badge, int index, Color color) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${badge.slug}_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Tooltip(
        message: '${badge.name}\n${badge.description}',
        triggerMode: TooltipTriggerMode.tap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SizedBox(
                width: 32,
                height: 32,
                child: badge.iconUrl != null
                    ? AppNetworkImage(url: badge.iconUrl!, fit: BoxFit.contain)
                    : Icon(
                        Icons.military_tech,
                        size: 32,
                        color: color,
                      ),
              ),
            ),
            if (badge.count > 1)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text(
                    'x${badge.count}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel? user, Color color) {
    final name = user?.name ?? '?';
    final photoUrl = user?.photoUrl;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: SizedBox(
        width: 32,
        height: 32,
        child: ClipOval(
          child: photoUrl != null
              ? AppNetworkImage(
                  url: photoUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(color: Colors.grey),
                )
              : Container(
                  color: Colors.grey,
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(RankingStatsModel stats, UserModel? user) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (user != null) ...[
            GestureDetector(
              onTap: () => _navigateToProfile(user),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Pontos', '${stats.points ?? 0}', isMain: true),
              _buildStatItem('Total', '${stats.total}'),
              _buildStatItem(
                'Exatos',
                '${stats.exactScore}',
                color: Colors.greenAccent,
              ),
              _buildStatItem(
                'Erros',
                '${stats.errors}',
                color: Colors.redAccent,
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Vencedor + Saldo', '${stats.winnerDiff}'),
              _buildStatItem('Vencedor + Gols', '${stats.winnerGoal}'),
              _buildStatItem('Apenas Vencedor', '${stats.winnerOnly}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    bool isMain = false,
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isMain ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamLogo(String? url) {
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

  Widget _buildPredictionCard(
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '-',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    final points = prediction.pointsEarned ?? 0;
    final isWin = points > 0;
    final pointsText = points > 0 ? '+$points' : '$points';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isWin
            ? color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWin ? color.withValues(alpha: 0.6) : Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
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
            ],
          ),
        ],
      ),
    );
  }
}
