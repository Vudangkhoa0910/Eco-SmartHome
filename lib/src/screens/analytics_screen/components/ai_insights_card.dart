import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';

class AIInsightsCard extends StatelessWidget {
  final Map<String, dynamic> insights;
  final VoidCallback? onViewDetails;

  const AIInsightsCard({
    Key? key,
    required this.insights,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final summary = insights['summary'] ?? {};
    final insightsList = insights['insights'] ?? [];
    final recommendations = insights['recommendations'] ?? [];

    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insights',
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(18),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    if (summary['message'] != null)
                      Text(
                        summary['message'],
                        style: TextStyle(
                          fontSize: getProportionateScreenWidth(12),
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              // Status Score
              if (summary['score'] != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(summary['score']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${summary['score']}',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(14),
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(summary['score']),
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: getProportionateScreenHeight(16)),
          
          // Top Insights
          if (insightsList.isNotEmpty) ...[
            Text(
              'Thông tin quan trọng:',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(14),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(8)),
            ...insightsList.take(3).map<Widget>((insight) => _buildInsightItem(context, insight)),
          ],
          
          SizedBox(height: getProportionateScreenHeight(12)),
          
          // Top Recommendations
          if (recommendations.isNotEmpty) ...[
            Text(
              'Đề xuất tối ưu:',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(14),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(8)),
            ...recommendations.take(2).map<Widget>((rec) => _buildRecommendationItem(context, rec)),
          ],
          
          // View Details Button
          if (onViewDetails != null) ...[
            SizedBox(height: getProportionateScreenHeight(12)),
            Center(
              child: TextButton.icon(
                onPressed: onViewDetails,
                icon: Icon(Icons.analytics_outlined, size: 18),
                label: Text('Xem báo cáo chi tiết'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, Map<String, dynamic> insight) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getInsightTypeColor(insight['type'] ?? '').withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getInsightTypeIcon(insight['type'] ?? ''),
            size: 16,
            color: _getInsightTypeColor(insight['type'] ?? ''),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] ?? '',
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleSmall?.color,
                  ),
                ),
                if (insight['description'] != null) ...[
                  SizedBox(height: 2),
                  Text(
                    insight['description'],
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(10),
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Priority indicator
          if (insight['priority'] != null)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getPriorityColor(insight['priority']),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(BuildContext context, Map<String, dynamic> recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: Colors.green,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['action'] ?? '',
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleSmall?.color,
                  ),
                ),
                if (recommendation['savings'] != null) ...[
                  SizedBox(height: 2),
                  Text(
                    'Tiết kiệm: ${recommendation['savings']}',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(10),
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Difficulty indicator
          if (recommendation['difficulty'] != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getDifficultyColor(recommendation['difficulty']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                recommendation['difficulty'],
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(8),
                  color: _getDifficultyColor(recommendation['difficulty']),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getInsightTypeColor(String type) {
    switch (type) {
      case 'tiết_kiệm': return Colors.green;
      case 'cảnh_báo': return Colors.red;
      case 'tối_ưu': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getInsightTypeIcon(String type) {
    switch (type) {
      case 'tiết_kiệm': return Icons.savings;
      case 'cảnh_báo': return Icons.warning;
      case 'tối_ưu': return Icons.tune;
      default: return Icons.info;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'cao': return Colors.red;
      case 'trung_bình': return Colors.orange;
      default: return Colors.green;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'dễ': return Colors.green;
      case 'trung_bình': return Colors.orange;
      default: return Colors.red;
    }
  }
}
