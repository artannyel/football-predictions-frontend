import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/blinking_live_indicator.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/auth/data/models/user_model.dart';
import 'package:football_predictions/features/home/data/models/league_ranking_model.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:football_predictions/features/predictions/data/models/prediction_model.dart';
import 'package:football_predictions/features/predictions/data/repositories/predictions_repository.dart';
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
                return Column(
                  children: [
                    _buildStatsHeader(_userStats!, _userHistory),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text("VS",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    _buildStatsHeader(_meStats!, _meHistory),
                  ],
                );
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
            final showComparison = myPrediction != null && myPrediction.id != prediction.id;


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
                          if (_userHistory != null)
                            Text(
                              _userHistory!.name.split(' ').first,
                              style: const TextStyle(
                                  fontSize: 8, color: Colors.white70),
                            ),
                          _buildScore(prediction),
                          if (showComparison) ...[
                            const SizedBox(height: 4),
                            const Divider(height: 4, color: Colors.white24),
                            const SizedBox(height: 4),
                            const Text(
                              "Você",
                              style:
                                  TextStyle(fontSize: 8, color: Colors.white70),
                            ),
                            _buildScore(myPrediction),
                          ],
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
                    ],
                  ),
                ),
              ),
            );
          },
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
              onTap: user.photoUrl != null
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
                                  child: Image.network(
                                      user.photoUrl!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: SafeArea(
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
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
              child: CircleAvatar(
                radius: 40,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?',
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

  Widget _buildScore(PredictionModel prediction) {
    return Column(
      children: [
        Text(
          '${prediction.homeScore} x ${prediction.awayScore}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (prediction.pointsEarned != null)
          Text(
            '${prediction.pointsEarned} pts',
            style: TextStyle(
              fontSize: 10,
              color: prediction.pointsEarned == 0
                  ? Colors.redAccent
                  : Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
