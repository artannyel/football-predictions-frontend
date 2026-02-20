import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/core/presentation/widgets/radar_chart.dart';
import 'package:football_predictions/features/auth/data/models/user_model.dart';
import 'package:football_predictions/features/auth/data/repositories/auth_repository.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String? _error;
  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final repo = context.read<AuthRepository>();
      final profile = await repo.getUserProfile(userId: widget.userId);
      if (mounted) {
        setState(() {
          _profile = profile;
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          actions: [
            if (widget.userId == null)
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Configurações',
                onPressed: () => context.go('/perfil/configuracoes'),
              ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
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
            if (_isLoading)
              const Center(child: LoadingWidget())
            else if (_error != null)
              Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            else if (_profile != null)
              TweenAnimationBuilder<double>(
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildUserInfo(context, _profile!.user),
                      const SizedBox(height: 16),
                      _buildCareerStats(context, _profile!.career),
                      const SizedBox(height: 16),
                      _buildHallOfFame(context, _profile!.hallOfFame),
                      const SizedBox(height: 16),
                      _buildBadgesSection(context, _profile!.user.badges),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, UserModel user) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: user.photoUrl != null
                    ? AppNetworkImage(
                        url: user.photoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade800,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade800,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.userId == null) ...[
              const SizedBox(height: 8),
              Text(
                user.email,
                style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCareerStats(BuildContext context, CareerModel career) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final radar = career.radar;
    final values = [
      radar.precision.toDouble(),
      radar.technique.toDouble(),
      radar.safety.toDouble(),
    ];
    final labels = ['Placar exato', 'Vencedor + gols', 'Somente vencedor'];
    final displayLabels = List.generate(
      labels.length,
      (i) => '${labels[i]}\n${values[i]}%',
    );

    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Estatísticas da Carreira',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Pontos', career.totalPoints),
                  _buildStatItem('Palpites', career.totalPredictions),
                  _buildStatItem(
                    'Média',
                    career.averagePoints,
                    formatter: (v) => v.toStringAsFixed(2),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Win Rate',
                    career.winRate,
                    formatter: (v) => '${v.toStringAsFixed(1)}%',
                  ),
                  _buildStatItem('Ligas Ativas', career.activeLeaguesCount),
                  _buildStatItem('Ligas Final.', career.finishedLeaguesCount),
                ],
              ),
              Divider(height: 32, color: Theme.of(context).dividerColor),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return RadarChart(
                      values1: values,
                      labels: displayLabels,
                      maxValue: 100,
                      color1: isDark ? Colors.greenAccent : Theme.of(context).colorScheme.primary,
                      animationValue: value,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Palpites Recente',
                style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: career.recentForm.map((result) {
                  Color color;
                  IconData icon;
                  if (result == 'W') {
                    color = Colors.green;
                    icon = Icons.check_circle;
                  } else if (result == 'P') {
                    color = Colors.amber;
                    icon = Icons.star;
                  } else {
                    color = Colors.red;
                    icon = Icons.cancel;
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(icon, color: color, size: 20),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    num value, {
    String Function(num)? formatter,
  }) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value.toDouble()),
          duration: const Duration(seconds: 1),
          curve: Curves.easeOut,
          builder: (context, val, child) {
            return Text(
              formatter != null ? formatter(val) : val.toInt().toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            );
          },
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildHallOfFame(
    BuildContext context,
    List<HallOfFameModel> hallOfFame,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 Hall da Fama',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (hallOfFame.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.userId == null
                        ? 'Seu Hall da Fama está vazio.'
                        : 'Hall da Fama está vazio.',
                    style: TextStyle(color: onSurface.withOpacity(0.7)),
                  ),
                  if (widget.userId == null)
                    Text(
                      'Continue disputando as ligas para conquistar troféus!',
                      style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            )
          else
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: hallOfFame.length,
                itemBuilder: (context, index) {
                  final item = hallOfFame[index];
                  Color trophyColor;
                  String trophyIcon;
                  if (item.position == 1) {
                    trophyColor = Colors.amber;
                    trophyIcon = '🏆';
                  } else if (item.position == 2) {
                    trophyColor = const Color(0xFFC0C0C0);
                    trophyIcon = '🥈';
                  } else {
                    trophyColor = const Color(0xFFCD7F32);
                    trophyIcon = '🥉';
                  }

                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4, right: 4),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: trophyColor,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: item.avatarUrl != null
                                      ? AppNetworkImage(
                                          url: item.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: CircleAvatar(
                                            backgroundColor:
                                                Colors.grey.shade800,
                                            child: Text(
                                              item.name.isNotEmpty
                                                  ? item.name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        )
                                      : CircleAvatar(
                                          backgroundColor: Colors.grey.shade800,
                                          child: Text(
                                            item.name.isNotEmpty
                                                ? item.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Text(
                                trophyIcon,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.competitionName,
                            style: TextStyle(
                              fontSize: 10,
                              color: onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.year,
                            style: TextStyle(
                              fontSize: 10,
                              color: trophyColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, List<BadgeModel> badges) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medalhas e Conquistas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (badges.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.userId == null
                        ? 'Você ainda não possui medalhas.'
                        : 'Não possui medalhas',
                    style: TextStyle(color: onSurface.withOpacity(0.7)),
                  ),
                  if (widget.userId == null)
                    Text(
                      'Participe das ligas e acerte palpites para ganhar!',
                      style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: badge.description,
                      triggerMode: TooltipTriggerMode.tap,
                      child: GlassCard(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: badge.iconUrl != null
                                  ? AppNetworkImage(
                                      url: badge.iconUrl!,
                                      fit: BoxFit.contain,
                                    )
                                  : const Icon(
                                      Icons.military_tech,
                                      size: 40,
                                      color: Colors.amber,
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    badge.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (badge.count > 1) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                        begin: 0,
                                        end: badge.count.toDouble(),
                                      ),
                                      duration: const Duration(seconds: 1),
                                      curve: Curves.easeOut,
                                      builder: (context, val, child) {
                                        return Text(
                                          'x${val.toInt()}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
