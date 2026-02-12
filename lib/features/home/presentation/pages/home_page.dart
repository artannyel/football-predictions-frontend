import 'package:flutter/material.dart';
import 'package:football_predictions/core/auth/auth_notifier.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
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
  late Future<List<LeagueModel>> _leaguesFuture;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  void _loadLeagues() {
    _leaguesFuture = context.read<LeaguesRepository>().getLeagues();
  }

  Future<void> _refreshLeagues() async {
    setState(() {
      _leaguesFuture = context.read<LeaguesRepository>().getLeagues();
    });
    await _leaguesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Ligas'),
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
      body: FutureBuilder<List<LeagueModel>>(
        future: _leaguesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refreshLeagues,
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Text(
                        'Erro ao carregar ligas: ${snapshot.error.toString().replaceAll('Exception: ', '')}',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshLeagues,
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Você ainda não participa de nenhuma liga.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
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

          final leagues = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshLeagues,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: leagues.length,
              itemBuilder: (context, index) {
                final league = leagues[index];
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
                    trailing: Text(
                      '${league.myPoints} pts',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
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
                    _refreshLeagues();
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
                    _refreshLeagues();
                    if (mounted) {
                      context.go('/liga/${result.id}');
                    }
                  } else if (result == true) {
                    _refreshLeagues();
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
