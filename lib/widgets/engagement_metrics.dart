import 'package:flutter/material.dart';

class EngagementMetrics extends StatelessWidget {
  final int views;
  final int likes;
  final int shares;
  final int comments;
  final double engagementRate;
  final bool trendUp;

  const EngagementMetrics({
    Key? key,
    required this.views,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.engagementRate,
    this.trendUp = false,
  }) : super(key: key);

  String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricCard(
          icon: Icons.visibility,
          label: 'Views',
          value: formatNumber(views),
          trendUp: trendUp,
        ),
        _MetricCard(
          icon: Icons.favorite,
          label: 'Likes',
          value: formatNumber(likes),
          trendUp: trendUp,
        ),
        _MetricCard(
          icon: Icons.share,
          label: 'Shares',
          value: formatNumber(shares),
          trendUp: trendUp,
        ),
        _MetricCard(
          icon: Icons.comment,
          label: 'Comments',
          value: formatNumber(comments),
          trendUp: trendUp,
        ),
        _MetricCard(
          icon: Icons.trending_up,
          label: 'Engagement',
          value: '${engagementRate.toStringAsFixed(1)}%',
          trendUp: trendUp,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool trendUp;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trendUp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blueAccent),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (trendUp)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.arrow_upward, size: 12, color: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
