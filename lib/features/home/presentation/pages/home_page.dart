import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/auth/data/repositories/auth_repository.dart';
import 'package:football_predictions/features/competitions/presentation/pages/competitions_page.dart';
import 'package:football_predictions/features/home/data/models/league_model.dart';
import 'package:football_predictions/features/home/data/repositories/leagues_repository.dart';
import 'package:football_predictions/features/home/presentation/pages/create_league_page.dart';
import 'package:football_predictions/features/home/presentation/pages/league_details_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthRepository>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CompetitionsPage()),
          );
        },
        label: const Text('Ver Competições'),
        icon: const Icon(Icons.sports_soccer),
      ),
      body: FutureBuilder<List<LeagueModel>>(
        future: context.read<LeaguesRepository>().getLeagues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar ligas: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Você ainda não participa de nenhuma liga.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const CompetitionsPage()),
                      );
                    },
                    child: const Text('Explorar competições'),
                  ),
                ],
              ),
            );
          }

          final leagues = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: leagues.length,
            itemBuilder: (context, index) {
              final league = leagues[index];
              return Card(
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) =>
                              LeagueDetailsPage(leagueId: league.id)),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundImage: league.avatar != null
                        ? NetworkImage(league.avatar!)
                        : null,
                    child: league.avatar == null
                        ? Text(league.name[0].toUpperCase())
                        : null,
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
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Criar nova liga'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const CreateLeaguePage()),
                  );
                  if (result == true) {
                    setState(() {});
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.input),
                title: const Text('Entrar com código'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await showDialog(
                    context: context,
                    builder: (context) => const _JoinLeagueDialog(),
                  );
                  if (result == true) {
                    setState(() {});
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
      await context.read<LeaguesRepository>().joinLeague(code);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você entrou na liga!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
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