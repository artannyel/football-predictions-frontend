import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/core/presentation/widgets/web_constrained_box.dart';
import 'package:football_predictions/features/home/data/models/rule_model.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'league_ui_helpers.dart';

class RulesTab extends StatelessWidget {
  final Future<LeagueRulesModel> rulesFuture;

  const RulesTab({super.key, required this.rulesFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeagueRulesModel>(
      future: rulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        } else if (snapshot.hasError) {
          return buildScrollablePlaceholder(
            Text(
              'Erro ao carregar regras:\n${snapshot.error.toString().replaceAll('Exception: ', '')}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData) {
          return buildScrollablePlaceholder(
            const Text('Nenhuma regra encontrada.'),
          );
        }

        final rules = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(8),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (rules.scoring.isNotEmpty)
              WebConstrainedBox(
                child: GlassCard(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
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
              ),
            if (rules.tieBreakers.isNotEmpty)
              WebConstrainedBox(
                child: GlassCard(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
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
              ),
            if (rules.powerups.isNotEmpty)
              WebConstrainedBox(
                child: GlassCard(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ Powerups',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...rules.powerups.map(
                        (powerup) => Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurpleAccent,
                                foregroundColor: Colors.white,
                                child: const Icon(Icons.style, size: 20),
                              ),
                              title: Text(
                                powerup.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(powerup.description),
                            ),
                            if (powerup != rules.powerups.last) const Divider(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (rules.badges.isNotEmpty)
              WebConstrainedBox(
                child: GlassCard(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏅 Medalhas e Conquistas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...rules.badges.map(
                        (badge) => Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: SizedBox(
                                width: 48,
                                height: 48,
                                child: badge.iconUrl != null
                                    ? AppNetworkImage(
                                        url: badge.iconUrl!,
                                        fit: BoxFit.contain,
                                      )
                                    : const Icon(
                                        Icons.military_tech,
                                        size: 32,
                                        color: Colors.amber,
                                      ),
                              ),
                              title: Text(
                                badge.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(badge.description),
                            ),
                            if (badge != rules.badges.last) const Divider(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}