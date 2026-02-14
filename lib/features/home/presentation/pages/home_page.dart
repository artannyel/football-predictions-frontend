import 'package:flutter/material.dart';
import 'package:football_predictions/core/auth/auth_notifier.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/competitions/data/models/competition_model.dart';
import 'package:football_predictions/features/competitions/data/repositories/competitions_repository.dart';
import 'package:football_predictions/features/home/data/models/league_model.dart';
import 'package:football_predictions/features/home/data/repositories/leagues_repository.dart';
import 'package:football_predictions/features/home/presentation/pages/create_league_page.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<_LeaguesTabState> _activeTabKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Ligas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ativas'),
              Tab(text: 'Finalizadas'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddOptions(context),
            ),
          ],
        ),
        drawer: Drawer(
          child: Consumer<AuthNotifier>(
            builder: (context, authNotifier, child) {
              // Obtém o usuário já carregado no AuthNotifier
              final user = authNotifier.backendUser;
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(
                      user?.name ?? 'Usuário',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    accountEmail: Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: user?.photoUrl != null
                            ? AppNetworkImage(
                                url: user!.photoUrl!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorWidget: const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Editar Perfil'),
                    onTap: () async {
                      Navigator.pop(context); // Fecha o drawer
                      context.go('/perfil');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sair'),
                    onTap: () async {
                      Navigator.pop(context);
                      await context.read<AuthNotifier>().logout();
                    },
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.go('/competicoes');
          },
          label: const Text('Ver Competições'),
          icon: const Icon(Icons.sports_soccer),
        ),
        body: TabBarView(
          children: [
            _LeaguesTab(key: _activeTabKey, status: 'active'),
            const _LeaguesTab(status: 'finished'),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Criar nova liga'),
                onTap: () async {
                  Navigator.pop(modalContext);
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateLeaguePage(),
                    ),
                  );
                  if (result == true) {
                    _activeTabKey.currentState?.refresh();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.input),
                title: const Text('Entrar com código'),
                onTap: () async {
                  Navigator.pop(modalContext);
                  final result = await showDialog(
                    context: context,
                    builder: (context) => const _JoinLeagueDialog(),
                  );
                  if (result is LeagueModel) {
                    _activeTabKey.currentState?.refresh();
                    if (mounted) {
                      context.go('/liga/${result.id}');
                    }
                  } else if (result == true) {
                    _activeTabKey.currentState?.refresh();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaguesTab extends StatefulWidget {
  final String status;
  const _LeaguesTab({super.key, required this.status});

  @override
  State<_LeaguesTab> createState() => _LeaguesTabState();
}

class _LeaguesTabState extends State<_LeaguesTab>
    with AutomaticKeepAliveClientMixin {
  final List<LeagueModel> _leagues = [];
  final TextEditingController _searchController = TextEditingController();
  int _page = 1;
  int _lastPage = 1;
  bool _isLoading = false;
  String? _error;
  int? _selectedCompetitionId;
  String? _searchName;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadLeagues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLeagues({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _page = 1;
      _lastPage = 1;
      _leagues.clear();
      _error = null;
    } else if (_page > _lastPage) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await context.read<LeaguesRepository>().getLeagues(
            page: _page,
            competitionId: _selectedCompetitionId,
            name: _searchName,
            status: widget.status,
          );
      if (mounted) {
        setState(() {
          _leagues.addAll(result.leagues);
          _lastPage = result.lastPage;
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

  Future<void> refresh() => _refreshLeagues();

  Future<void> _refreshLeagues() async {
    await _loadLeagues(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildFilters(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar liga',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchName = null);
                        _loadLeagues(refresh: true);
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              setState(() => _searchName = value.isEmpty ? null : value);
              _loadLeagues(refresh: true);
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<CompetitionModel>>(
            future: context.read<CompetitionsRepository>().getCompetitions(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return DropdownButtonFormField<int>(
                value: _selectedCompetitionId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Competição',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as competições'),
                  ),
                  ...snapshot.data!.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(
                        children: [
                          if (c.emblem != null) ...[
                            AppNetworkImage(
                              url: c.emblem!,
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              errorWidget: const Icon(
                                Icons.sports_soccer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                              child: Text(c.name,
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedCompetitionId = value);
                  _loadLeagues(refresh: true);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_leagues.isEmpty && _isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (_leagues.isEmpty && _error != null) {
      return RefreshIndicator(
        onRefresh: _refreshLeagues,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Text('Erro ao carregar ligas: $_error'),
              ),
            ),
          ],
        ),
      );
    }

    if (_leagues.isEmpty) {
      if (_searchName != null || _selectedCompetitionId != null) {
        return RefreshIndicator(
          onRefresh: _refreshLeagues,
          child: ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(
                  child: Text(
                      'Nenhuma liga encontrada com os filtros selecionados.'),
                ),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: _refreshLeagues,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    widget.status == 'finished'
                        ? 'Você ainda não participou de nenhuma liga finalizada.'
                        : 'Você ainda não participa de nenhuma liga.',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      context.go('/competicoes');
                    },
                    child: const Text('Explorar competições'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isLoading &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _loadLeagues();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: _refreshLeagues,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _leagues.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _leagues.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: LoadingWidget(size: 30)),
              );
            }

            final league = _leagues[index];
            return Card(
              child: ListTile(
                onTap: () {
                  context.go('/liga/${league.id}');
                },
                leading: SizedBox(
                  width: 40,
                  height: 40,
                  child: ClipOval(
                    child: league.avatar != null
                        ? AppNetworkImage(
                            url: league.avatar!,
                            fit: BoxFit.cover,
                            errorWidget: CircleAvatar(
                              child: Text(league.name[0].toUpperCase()),
                            ),
                          )
                        : CircleAvatar(
                            child: Text(league.name[0].toUpperCase()),
                          ),
                  ),
                ),
                title: Text(
                  league.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(league.competition.name),
                    Text('Criado por: ${league.owner.name}'),
                    Text('${league.membersCount} participantes'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${league.myPoints} pts',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (league.pendingPredictionsCount != null &&
                        league.pendingPredictionsCount! > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${league.pendingPredictionsCount} palpites',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
}

class _JoinLeagueDialog extends StatefulWidget {
  const _JoinLeagueDialog();

  @override
  State<_JoinLeagueDialog> createState() => _JoinLeagueDialogState();
}

class _JoinLeagueDialogState extends State<_JoinLeagueDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinLeague() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final league = await context.read<LeaguesRepository>().joinLeague(code);
      if (mounted) {
        Navigator.pop(context, league);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Você entrou na liga!')));
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Entrar em uma Liga'),
      content: TextField(
        controller: _codeController,
        decoration: const InputDecoration(
          labelText: 'Código da Liga',
          hintText: 'Ex: FLQHHX',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.characters,
        enabled: !_isLoading,
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _joinLeague,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('ENTRAR'),
        ),
      ],
    );
  }
}
