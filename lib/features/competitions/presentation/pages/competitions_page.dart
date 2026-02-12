import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/competitions/data/models/competition_model.dart';
import 'package:football_predictions/features/competitions/data/repositories/competitions_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CompetitionsPage extends StatelessWidget {
  const CompetitionsPage({super.key});

  void _onBackPage(BuildContext context) {
    context.go('/ligas');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (canPop, _) {
        _onBackPage(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Competições'),
          leading: IconButton(
            onPressed: () => _onBackPage(context),
            icon: Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: FutureBuilder<List<CompetitionModel>>(
          future: context.read<CompetitionsRepository>().getCompetitions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingWidget());
            }
      
            if (snapshot.hasError) {
              return Center(
                child: Text('Erro ao carregar dados: ${snapshot.error}'),
              );
            }
      
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhuma competição encontrada.'));
            }
      
            final competitions = snapshot.data!;
      
            return ListView.builder(
              itemCount: competitions.length,
              itemBuilder: (context, index) {
                final competition = competitions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    onTap: () {
                      context.go('/competicao/${competition.id}/partidas');
                    },
                    leading: competition.emblem != null
                        ? AppNetworkImage(
                            url: competition.emblem!,
                            width: 40,
                            height: 40,
                            errorWidget: const Icon(Icons.sports_soccer),
                          )
                        : const Icon(Icons.sports_soccer),
                    title: Text(
                      competition.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(competition.areaName),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}