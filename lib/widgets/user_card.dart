import 'package:flutter/material.dart';
import 'package:tsukuani/models/user_profile.dart';
import 'package:tsukuani/widgets/badge_display.dart';

class UserCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onFollowPressed;
  final bool isFollowing;

  const UserCard({
    Key? key,
    required this.profile,
    this.onFollowPressed,
    this.isFollowing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: profile.profileImageUrl != null
                          ? NetworkImage(profile.profileImageUrl!)
                          : null,
                      child: profile.profileImageUrl == null
                          ? Text(profile.displayName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${profile.followerCount} followers',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                if (onFollowPressed != null)
                  ElevatedButton.icon(
                    onPressed: onFollowPressed,
                    icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
                    label: Text(isFollowing ? 'Unfollow' : 'Follow'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (profile.bio != null && profile.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  profile.bio!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Wrap(
              spacing: 16,
              children: [
                Column(
                  children: [
                    Text(
                      '${profile.totalVideos}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Videos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${(profile.totalViews / 1000).toStringAsFixed(0)}K',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Views',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      profile.averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Rating',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            if (profile.badges.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: BadgeDisplay(badges: profile.badges),
              ),
          ],
        ),
      ),
    );
  }
}
