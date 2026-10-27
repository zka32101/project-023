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
  late RankingPeriod _selectedPeriod;
  List<RankedVideo> rankedVideos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.period;
    rankingService = VideoRankingService.instance;
    loadRanking();
  }

  Future<void> loadRanking() async {
    setState(() => isLoading = true);

    final videos = switch (_selectedPeriod) {
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
    return switch (_selectedPeriod) {
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

  Widget _buildPeriodButton(String label, RankingPeriod period) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedPeriod = period);
        loadRanking();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blueAccent : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getPeriodLabel()),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodButton('Daily', RankingPeriod.daily),
                _buildPeriodButton('Weekly', RankingPeriod.weekly),
                _buildPeriodButton('Monthly', RankingPeriod.monthly),
              ],
            ),
          ),
        ),
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
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 120,
                              color: Colors.grey[300],
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/placeholder_video.png',
                                    width: double.infinity,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const SizedBox.expand(),
                                  ),
                                  Icon(
                                    Icons.play_circle_outline,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ],
                              ),
                            ),
                            ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    'Rank #${video.rank}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(video.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 16,
                                    children: [
                                      Text('Views: ${formatNumber(video.viewCount)}'),
                                      Text('Likes: ${formatNumber(video.likeCount)}'),
                                      Text('Shares: ${formatNumber(video.shareCount)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Score: ${video.engagementScore.toStringAsFixed(2)}'),
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
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
