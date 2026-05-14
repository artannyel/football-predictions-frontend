import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/core/presentation/widgets/web_constrained_box.dart';
import 'package:football_predictions/features/home/data/models/league_feed_model.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:go_router/go_router.dart';
import 'league_ui_helpers.dart';

class FeedTab extends StatelessWidget {
  final String? feedError;
  final List<LeagueFeedModel> feedItems;
  final bool isFeedLoading;
  final VoidCallback onLoadMore;
  final String leagueId;

  const FeedTab({
    super.key,
    required this.feedError,
    required this.feedItems,
    required this.isFeedLoading,
    required this.onLoadMore,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context) {
    if (feedError != null && feedItems.isEmpty) {
      return buildScrollablePlaceholder(
        Text(
          'Erro ao carregar feed:\n$feedError',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (feedItems.isEmpty && isFeedLoading) {
      return const LoadingWidget();
    }

    if (feedItems.isEmpty) {
      return buildScrollablePlaceholder(
        const Text('Nenhuma atividade recente.'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!isFeedLoading &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        key: const PageStorageKey('feed'),
        padding: const EdgeInsets.all(8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: feedItems.length + (isFeedLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == feedItems.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: LoadingWidget(size: 30)),
            );
          }

          final item = feedItems[index];
          final user = item.user;
          final badge = item.badge;
          final match = item.match;

          return WebConstrainedBox(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('feed_${item.id}'),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
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
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go(
                            '/ligas/$leagueId/usuario/${user.id}',
                          ),
                          child: ClipOval(
                            child: user.photoUrl != null
                                ? AppNetworkImage(
                                    url: user.photoUrl!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                  )
                                : CircleAvatar(
                                    radius: 16,
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    TextSpan(
                                      text: user.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' conquistou a medalha ',
                                    ),
                                    TextSpan(
                                      text: badge.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.amber
                                            : Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatRelativeTime(item.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: badge.iconUrl != null
                              ? AppNetworkImage(
                                  url: badge.iconUrl!,
                                  errorWidget: const Icon(
                                    Icons.military_tech,
                                    size: 32,
                                    color: Colors.amber,
                                  ),
                                )
                              : const Icon(
                                  Icons.military_tech,
                                  size: 32,
                                  color: Colors.amber,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: match != null
                                ? Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          buildTeamLogo(match.homeTeamCrest),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${match.homeScore ?? '-'} x ${match.awayScore ?? '-'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          buildTeamLogo(match.awayTeamCrest),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${match.homeTeamName} vs ${match.awayTeamName}',
                                        style: const TextStyle(fontSize: 10),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  )
                                : Text(
                                    badge.description.replaceAll(
                                      'em uma',
                                      'na',
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
