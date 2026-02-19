import 'package:flutter/material.dart';
import 'package:football_predictions/core/auth/auth_notifier.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:football_predictions/features/ranking/data/models/global_ranking_model.dart';
import 'package:football_predictions/features/ranking/data/models/global_rules_model.dart';
import 'package:football_predictions/features/ranking/data/repositories/ranking_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ranking Global'),
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Eterno'),
              Tab(text: 'Anual'),
              Tab(text: 'Mensal'),
              Tab(text: 'Regras'),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Background
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
            const TabBarView(
              children: [
                _RankingListTab(type: _RankingType.global),
                _RankingListTab(type: _RankingType.annual),
                _RankingListTab(type: _RankingType.monthly),
                _RankingRulesTab(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _RankingType { global, annual, monthly }

class _RankingListTab extends StatefulWidget {
  final _RankingType type;

  const _RankingListTab({required this.type});

  @override
  State<_RankingListTab> createState() => _RankingListTabState();
}

class _RankingListTabState extends State<_RankingListTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  String? _error;
  GlobalRankingModel? _rankingData;

  // Filtros
  String? _selectedPeriod;
  final List<String> _availableYears = [];
  final List<Map<String, String>> _availableMonths = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupFilters();
    _loadRanking();
  }

  void _setupFilters() {
    final now = DateTime.now();
    final startYear = 2026;
    final startMonth = 2; // Fevereiro

    if (widget.type == _RankingType.annual) {
      // Gera anos de 2026 até o atual
      for (int year = startYear; year <= now.year; year++) {
        _availableYears.add(year.toString());
      }
      // Seleciona o ano atual por padrão
      _selectedPeriod = now.year.toString();
      // Se o ano atual for menor que 2026 (ex: testando em 2025), força 2026
      if (now.year < startYear) _selectedPeriod = '2026';
    } else if (widget.type == _RankingType.monthly) {
      // Gera meses de Fev/2026 até o atual
      DateTime current = DateTime(startYear, startMonth);
      // Se estivermos antes de Fev/2026, ajusta para começar lá
      if (now.isBefore(current)) {
        // Apenas para evitar crash em testes antes da data de lançamento
      }

      while (current.isBefore(now) ||
          (current.year == now.year && current.month == now.month)) {
        final periodValue = DateFormat('yyyy-MM').format(current);
        final label =
            '${_getMonthName(current.month)} ${current.year}'; // Ex: Fevereiro 2026
        _availableMonths.add({'value': periodValue, 'label': label});

        // Avança um mês
        current = DateTime(current.year, current.month + 1);
      }

      // Ordena decrescente (mais recente primeiro)
      _availableMonths.sort((a, b) => b['value']!.compareTo(a['value']!));

      if (_availableMonths.isNotEmpty) {
        _selectedPeriod = _availableMonths.first['value'];
      } else {
        // Fallback
        _selectedPeriod = '2026-02';
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return months[month - 1];
  }

  Future<void> _loadRanking() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<RankingRepository>();
      final result = await repo.getGlobalRanking(period: _selectedPeriod);

      if (mounted) {
        setState(() {
          _rankingData = result;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        if (widget.type != _RankingType.global) _buildFilterDropdown(),
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingWidget())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRanking,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.white70),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                dropdownColor: const Color(0xFF1B5E20),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                isExpanded: true,
                items: widget.type == _RankingType.annual
                    ? _availableYears.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text('Temporada $year'),
                        );
                      }).toList()
                    : _availableMonths.map((month) {
                        return DropdownMenuItem(
                          value: month['value'],
                          child: Text(month['label']!),
                        );
                      }).toList(),
                onChanged: (value) {
                  if (value != null && value != _selectedPeriod) {
                    setState(() => _selectedPeriod = value);
                    _loadRanking();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_rankingData == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadRanking,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMyRankCard(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'TOP 10 JOGADORES',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_rankingData!.topList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Nenhum jogador pontuou neste período ainda.',
                              style: TextStyle(color: Colors.white60),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        _buildRankingTable(),
                    
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTable() {
    final currentUserId = context.read<AuthNotifier>().backendUser?.id;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columnSpacing: 20,
        headingRowHeight: 40,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 48,
        columns: const [
          DataColumn(label: Text('#'), numeric: true),
          DataColumn(label: Text('Jogador')),
          DataColumn(
            label: Tooltip(message: 'Placar Exato', child: Text('PE')),
            numeric: true,
          ),
          DataColumn(
            label: Tooltip(message: 'Vencedor + Saldo', child: Text('VS')),
            numeric: true,
          ),
          DataColumn(
            label: Tooltip(message: 'Vencedor + Gols', child: Text('VG')),
            numeric: true,
          ),
          DataColumn(
            label: Tooltip(message: 'Apenas Vencedor', child: Text('AV')),
            numeric: true,
          ),
          DataColumn(
            label: Tooltip(message: 'Erros', child: Text('ER')),
            numeric: true,
          ),
          DataColumn(label: Text('Pts'), numeric: true),
          DataColumn(
            label: Tooltip(message: 'Total de Palpites', child: Text('TOT')),
            numeric: true,
          ),
        ],
        rows: _rankingData!.topList.map((user) {
          final isCurrentUser = user.userId == currentUserId;
          return DataRow(
            color: isCurrentUser
                ? MaterialStateProperty.all(
                    Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  )
                : null,
            onSelectChanged: user.userId != null
                ? (_) {
                    context.pushNamed(
                      'UserProfile',
                      pathParameters: {'userId': user.userId!},
                    );
                  }
                : null,
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${user.rank}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getRankColor(user.rank),
                      ),
                    ),
                    if (user.rank <= 3) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: _getRankColor(user.rank),
                      ),
                    ],
                  ],
                ),
              ),
              DataCell(
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: ClipOval(
                        child: user.photoUrl != null
                            ? AppNetworkImage(
                                url: user.photoUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey,
                                child: Center(
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              DataCell(Text('${user.stats.exactScore}')),
              DataCell(Text('${user.stats.winnerDiff}')),
              DataCell(Text('${user.stats.winnerGoal}')),
              DataCell(Text('${user.stats.winnerOnly}')),
              DataCell(Text('${user.stats.errors}')),
              DataCell(Text('${user.points}')),
              DataCell(Text('${user.stats.total}')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMyRankCard() {
    final myRank = _rankingData!.myRank;

    if (myRank == null) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              'Você ainda não está no ranking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Faça seus palpites e acerte os placares para começar a pontuar e disputar com os melhores!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/competicoes'),
              child: const Text('COMEÇAR A PALPITAR'),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'RANK',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '#${myRank.rank}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seu Desempenho',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      myRank.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${myRank.points} pontos',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Exatos',
                myRank.stats.exactScore,
                Colors.cyanAccent,
              ),
              _buildStatItem('Saldos', myRank.stats.winnerDiff, Colors.white70),
              _buildStatItem('Gols', myRank.stats.winnerGoal, Colors.white70),
              _buildStatItem(
                'Vencedor',
                myRank.stats.winnerOnly,
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.white;
  }
}

class _RankingRulesTab extends StatelessWidget {
  const _RankingRulesTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GlobalRulesModel>(
      future: context.read<RankingRepository>().getGlobalRules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingWidget());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar regras: ${snapshot.error.toString().replaceAll('Exception: ', '')}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        if (!snapshot.hasData) return const SizedBox();

        final rules = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.public,
                    size: 48,
                    color: Colors.lightBlueAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    rules.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rules.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...rules.rules.map((rule) => _buildRuleItem(context, rule)),
          ],
        );
      },
    );
  }

  Widget _buildRuleItem(BuildContext context, GlobalRuleItem rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rule.description,
                    style: const TextStyle(color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
