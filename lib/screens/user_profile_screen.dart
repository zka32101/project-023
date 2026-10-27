import 'package:flutter/material.dart';
import 'package:tsukuani/models/user_profile.dart';
import 'package:tsukuani/services/user_profile_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? currentUserId;
  final bool isOwnProfile;
  final bool showVideosTab;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    this.currentUserId,
    this.isOwnProfile = false,
    this.showVideosTab = true,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late UserProfileService profileService;
  late TabController tabController;

  UserProfile? profile;
  bool isLoading = true;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    profileService = UserProfileService.instance;
    tabController = TabController(
      length: widget.showVideosTab ? 2 : 1,
      vsync: this,
    );
    loadProfile();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    setState(() => isLoading = true);

    final loadedProfile = await profileService.getUserProfile(widget.userId);
    bool following = false;

    if (widget.currentUserId != null) {
      following = await profileService.isFollowing(widget.currentUserId!, widget.userId);
    }

    setState(() {
      profile = loadedProfile;
      isFollowing = following;
      isLoading = false;
    });
  }

  Future<void> toggleFollow() async {
    if (widget.currentUserId == null || profile == null) return;

    if (isFollowing) {
      await profileService.unfollowUser(widget.currentUserId!, widget.userId);
    } else {
      await profileService.followUser(widget.currentUserId!, widget.userId);
    }

    await loadProfile();
  }

  String getStarRating(double rating) {
    int fullStars = rating.toInt();
    bool hasHalf = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);

    String stars = '★' * fullStars;
    if (hasHalf) stars += '✩';
    stars += '☆' * emptyStars;
    return stars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? Center(
                  child: Text(
                    'Profile not found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        color: Colors.grey[100],
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: profile!.profileImageUrl != null
                                      ? NetworkImage(profile!.profileImageUrl!)
                                      : null,
                                  child: profile!.profileImageUrl == null
                                      ? Text(profile!.displayName[0].toUpperCase())
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              profile!.displayName,
                                              style: Theme.of(context).textTheme.titleLarge,
                                            ),
                                          ),
                                          if (profile!.isVerified)
                                            const Icon(
                                              Icons.verified,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text('Followers: ${profile!.followerCount}'),
                                          const SizedBox(width: 16),
                                          Text('Following: ${profile!.followingCount}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (profile!.bio != null && profile!.bio!.isNotEmpty)
                              Text(profile!.bio!),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (!widget.isOwnProfile && widget.currentUserId != null)
                                  ElevatedButton.icon(
                                    onPressed: toggleFollow,
                                    icon: Icon(
                                      isFollowing ? Icons.person_remove : Icons.person_add,
                                    ),
                                    label: Text(isFollowing ? 'Unfollow' : 'Follow'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Statistics
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistics',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _StatCard(
                                  label: 'Videos',
                                  value: profile!.totalVideos.toString(),
                                ),
                                _StatCard(
                                  label: 'Views',
                                  value: '${(profile!.totalViews / 1000).toStringAsFixed(1)}K',
                                ),
                                _StatCard(
                                  label: 'Likes',
                                  value: '${(profile!.totalLikes / 1000).toStringAsFixed(1)}K',
                                ),
                                _StatCard(
                                  label: 'Rating',
                                  value: profile!.averageRating.toStringAsFixed(1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Engagement Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Engagement',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text('Rate: ${profile!.getEngagementRate().toStringAsFixed(1)}%'),
                                const SizedBox(width: 24),
                                Text(
                                  'Avg Views/Video: ${profile!.getAverageViewsPerVideo().toStringAsFixed(1)}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Badges
                      if (profile!.badges.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Badges',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: profile!.badges.map((badge) {
                                  return Chip(
                                    avatar: const Icon(Icons.star),
                                    label: Text(badge.name),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      // Social Links
                      if (profile!.socialLinks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Social Links',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ...profile!.socialLinks.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Text('${entry.key}:'),
                                      const SizedBox(width: 8),
                                      Text(entry.value),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
      bottomNavigationBar: widget.showVideosTab
          ? BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
                BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Videos'),
              ],
            )
          : null,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
