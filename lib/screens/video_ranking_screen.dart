import 'package:flutter/material.dart';
import 'package:tsukuani/models/video_ranking.dart';
import 'package:tsukuani/services/video_ranking_service.dart';

class VideoRankingScreen extends StatefulWidget {
  final RankingPeriod period;
  final int? limit;

  const VideoRankingScreen({
    Key? key,
    required this.period,
    this.limit,
  }) : super(key: key);

  @override
  State<VideoRankingScreen> createState() => _VideoRankingScreenState();
}

class _VideoRankingScreenState extends State<VideoRankingScreen> {
  late VideoRankingService rankingService;
  List<RankedVideo> rankedVideos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    rankingService = VideoRankingService.instance;
    loadRanking();
  }

  Future<void> loadRanking() async {
    setState(() => isLoading = true);

    final videos = switch (widget.period) {
      RankingPeriod.daily => await rankingService.getDailyRanking(limit: widget.limit),
      RankingPeriod.weekly => await rankingService.getWeeklyRanking(limit: widget.limit),
      RankingPeriod.monthly => await rankingService.getMonthlyRanking(limit: widget.limit),
    };

    setState(() {
      rankedVideos = videos;
      isLoading = false;
    });
  }

  String getPeriodLabel() {
    return switch (widget.period) {
      RankingPeriod.daily => 'Daily Ranking',
      RankingPeriod.weekly => 'Weekly Ranking',
      RankingPeriod.monthly => 'Monthly Ranking',
    };
  }

  String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
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
        title: Text(getPeriodLabel()),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : rankedVideos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No videos to rank yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: rankedVideos.length,
                  itemBuilder: (context, index) {
                    final video = rankedVideos[index];
                    return ListTile(
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Rank #${video.rank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(video.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Views: ${formatNumber(video.viewCount)} | Likes: ${formatNumber(video.likeCount)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Shares: ${formatNumber(video.shareCount)} | Score: ${video.engagementScore.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            getStarRating(video.averageRating),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.trending_up,
                        color: Colors.green[600],
                      ),
                      onTap: () {
                        // Navigate to video details
                      },
                    );
                  },
                ),
    );
  }
}
