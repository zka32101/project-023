import 'package:flutter/material.dart';
import 'package:tsukuani/models/user_profile.dart';

class BadgeDisplay extends StatelessWidget {
  final List<UserBadge> badges;

  const BadgeDisplay({
    Key? key,
    required this.badges,
  }) : super(key: key);

  String getBadgeLabel(UserBadge badge) {
    return switch (badge) {
      UserBadge.verified => 'Verified',
      UserBadge.topCreator => 'Top Creator',
      UserBadge.trendingSetter => 'Trending Setter',
      UserBadge.communityHelper => 'Community Helper',
      UserBadge.earlyAdopter => 'Early Adopter',
      UserBadge.milestone100k => '100K Milestone',
      UserBadge.milestone1m => '1M Milestone',
    };
  }

  IconData getBadgeIcon(UserBadge badge) {
    return switch (badge) {
      UserBadge.verified => Icons.verified,
      UserBadge.topCreator => Icons.star,
      UserBadge.trendingSetter => Icons.trending_up,
      UserBadge.communityHelper => Icons.support_agent,
      UserBadge.earlyAdopter => Icons.early_adopter,
      UserBadge.milestone100k => Icons.emoji_events,
      UserBadge.milestone1m => Icons.emoji_events,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      children: badges.map((badge) {
        return Tooltip(
          message: getBadgeLabel(badge),
          child: Chip(
            avatar: Icon(getBadgeIcon(badge), size: 18),
            label: Text(getBadgeLabel(badge)),
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    );
  }
}
