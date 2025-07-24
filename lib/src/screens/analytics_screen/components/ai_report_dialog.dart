import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/ai_analytics_service.dart';

class AIReportDialog extends StatefulWidget {
  final Map<String, dynamic> insights;
  final Map<String, dynamic> deviceStats;
  final double monthlyConsumption;
  final double monthlyCost;

  const AIReportDialog({
    Key? key,
    required this.insights,
    required this.deviceStats,
    required this.monthlyConsumption,
    required this.monthlyCost,
  }) : super(key: key);

  @override
  State<AIReportDialog> createState() => _AIReportDialogState();
}

class _AIReportDialogState extends State<AIReportDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingReport = false;
  String _optimizationReport = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOptimizationReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOptimizationReport() async {
    if (!mounted) return;
    setState(() => _isLoadingReport = true);
    
    try {
      final report = await AIAnalyticsService.generateOptimizationReport(
        deviceStats: widget.deviceStats,
        monthlyConsumption: widget.monthlyConsumption,
        monthlyCost: widget.monthlyCost,
      );
      
      if (!mounted) return;
      setState(() {
        _optimizationReport = report;
        _isLoadingReport = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optimizationReport = 'Không thể tải báo cáo tối ưu hóa';
        _isLoadingReport = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo AI Chi tiết',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          'Phân tích năng lượng và đề xuất tối ưu',
                          style: TextStyle(
                            fontSize: 12,
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.6),
              indicatorColor: Theme.of(context).primaryColor,
              tabs: [
                Tab(text: 'Insights'),
                Tab(text: 'Đề xuất'),
                Tab(text: 'Báo cáo'),
              ],
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInsightsTab(),
                  _buildRecommendationsTab(),
                  _buildReportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    final insights = widget.insights['insights'] ?? [];
    final summary = widget.insights['summary'] ?? {};
    final predictions = widget.insights['predictions'] ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildSummaryCard(summary),
          
          SizedBox(height: 16),
          
          // Insights List
          if (insights.isNotEmpty) ...[
            Text(
              'Chi tiết phân tích',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...insights.map<Widget>((insight) => _buildDetailedInsightCard(insight)),
          ],
          
          SizedBox(height: 16),
          
          // Predictions
          if (predictions.isNotEmpty) _buildPredictionsCard(predictions),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    final recommendations = widget.insights['recommendations'] ?? [];
    final deviceOptimization = widget.insights['device_optimization'] ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General Recommendations
          if (recommendations.isNotEmpty) ...[
            Text(
              'Đề xuất tổng quát',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...recommendations.map<Widget>((rec) => _buildRecommendationCard(rec)),
            SizedBox(height: 16),
          ],
          
          // Device Specific Recommendations
          if (deviceOptimization.isNotEmpty) ...[
            Text(
              'Tối ưu theo thiết bị',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...deviceOptimization.map<Widget>((device) => _buildDeviceRecommendationCard(device)),
          ],
        ],
      ),
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Báo cáo tối ưu hóa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_isLoadingReport)
                IconButton(
                  onPressed: _loadOptimizationReport,
                  icon: Icon(Icons.refresh),
                  tooltip: 'Làm mới báo cáo',
                ),
            ],
          ),
          SizedBox(height: 12),
          
          if (_isLoadingReport)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tạo báo cáo tối ưu hóa...'),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _optimizationReport,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'Tổng quan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (summary['message'] != null)
            Text(summary['message']),
          SizedBox(height: 8),
          Row(
            children: [
              Text('Điểm đánh giá: '),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(summary['score'] ?? 0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${summary['score'] ?? 0}/100',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(summary['score'] ?? 0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getInsightTypeColor(insight['type'] ?? '').withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getInsightTypeIcon(insight['type'] ?? ''),
                color: _getInsightTypeColor(insight['type'] ?? ''),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight['title'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (insight['priority'] != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(insight['priority']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    insight['priority'],
                    style: TextStyle(
                      fontSize: 10,
                      color: _getPriorityColor(insight['priority']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (insight['description'] != null) ...[
            SizedBox(height: 8),
            Text(insight['description']),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation['action'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                      fontSize: 10,
                      color: _getDifficultyColor(recommendation['difficulty']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (recommendation['reason'] != null) ...[
            SizedBox(height: 8),
            Text('Lý do: ${recommendation['reason']}'),
          ],
          if (recommendation['savings'] != null) ...[
            SizedBox(height: 4),
            Text(
              'Tiết kiệm: ${recommendation['savings']}',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceRecommendationCard(Map<String, dynamic> device) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.electrical_services, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  device['device'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (device['current_usage'] != null) ...[
            SizedBox(height: 8),
            Text('Hiện tại: ${device['current_usage']}'),
          ],
          if (device['optimization'] != null) ...[
            SizedBox(height: 4),
            Text(
              'Gợi ý: ${device['optimization']}',
              style: TextStyle(color: Colors.blue[700]),
            ),
          ],
          if (device['impact'] != null) ...[
            SizedBox(height: 4),
            Text(
              'Tác động: ${device['impact']}',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPredictionsCard(Map<String, dynamic> predictions) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Dự đoán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (predictions['monthly_cost_trend'] != null)
            _buildPredictionItem('Xu hướng chi phí', predictions['monthly_cost_trend']),
          if (predictions['estimated_monthly_bill'] != null)
            _buildPredictionItem('Ước tính hóa đơn', predictions['estimated_monthly_bill']),
          if (predictions['potential_savings'] != null)
            _buildPredictionItem('Tiềm năng tiết kiệm', predictions['potential_savings']),
        ],
      ),
    );
  }

  Widget _buildPredictionItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text('$label:'),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
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
