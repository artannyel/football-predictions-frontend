import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/web_constrained_box.dart';
import 'package:football_predictions/features/home/data/models/league_details_model.dart';
import 'package:football_predictions/features/home/data/models/league_ranking_model.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:share_plus/share_plus.dart';

class LeagueHeaderWidget extends StatefulWidget {
  final LeagueDetailsModel league;
  final List<LeagueRankingModel> rankings;

  const LeagueHeaderWidget({
    super.key,
    required this.league,
    required this.rankings,
  });

  @override
  State<LeagueHeaderWidget> createState() => _LeagueHeaderWidgetState();
}

class _LeagueHeaderWidgetState extends State<LeagueHeaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final league = widget.league;
    final rankings = widget.rankings;

    LeagueRankingModel? champion;
    LeagueRankingModel? viceChampion;
    LeagueRankingModel? thirdPlace;

    if (!league.isActive && rankings.isNotEmpty) {
      try {
        champion = rankings.firstWhere((r) => r.rank == 1);
      } catch (_) {}
      try {
        viceChampion = rankings.firstWhere((r) => r.rank == 2);
      } catch (_) {}
      try {
        thirdPlace = rankings.firstWhere((r) => r.rank == 3);
      } catch (_) {}
    }

    return WebConstrainedBox(
      child: GlassCard(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!league.isActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                  child: Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 4),
                    ),
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
              width: 110,
              height: 110,
              child: ClipOval(
                child: league.avatar != null
                    ? AppNetworkImage(
                        url: league.avatar!,
                        fit: BoxFit.cover,
                        errorWidget: CircleAvatar(
                          radius: 55,
                          child: Text(
                            league.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 55,
                        child: Text(
                          league.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 48),
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
            if (league.isActive)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepPurpleAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.style, color: Colors.deepPurpleAccent),
                    const SizedBox(width: 8),
                    Text(
                      '${league.myPowerups} Coringas disponíveis',
                      style: const TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Competição (Esquerda)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Competição',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (league.competition.emblem != null) ...[
                                  ClipOval(
                                    child: AppNetworkImage(
                                      url: league.competition.emblem!,
                                      width: 24,
                                      height: 24,
                                      errorWidget: const Icon(
                                        Icons.sports_soccer,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    league.competition.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Criador (Direita)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Criador',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    league.owner.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ClipOval(
                                  child: league.owner.photoUrl != null
                                      ? AppNetworkImage(
                                          url: league.owner.photoUrl!,
                                          width: 24,
                                          height: 24,
                                          errorWidget: const Icon(
                                            Icons.person,
                                            size: 24,
                                          ),
                                        )
                                      : const Icon(Icons.person, size: 24),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (league.isActive) ...[
                    const SizedBox(height: 16),
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.05).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: league.code),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Código copiado para a área de transferência!',
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.vpn_key,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      league.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(text: league.code),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Código copiado para a área de transferência!',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'COPIAR',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.copy,
                                          size: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    // TODO: Substituir pelo domínio real do seu app
                                    const String domain =
                                        'https://palpitesfutebol-b0f33.web.app';
                                    final String link =
                                        '$domain/?code=${league.code}';
                                    SharePlus.instance.share(
                                      ShareParams(
                                        text:
                                            'Venha participar da minha liga "${league.name}" no Palpites Futebol!\n\nEntre com o código: ${league.code}\nOu clique no link: $link',
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.share,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              : null,
          child: Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text('${member.points} pts', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
