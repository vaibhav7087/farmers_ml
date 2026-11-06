import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../../core/router.dart';

class YieldDetailScreen extends StatefulWidget {
  final String district;
  final String crop;

  const YieldDetailScreen({super.key, required this.district, required this.crop});

  @override
  State<YieldDetailScreen> createState() => _YieldDetailScreenState();
}

class _YieldDetailScreenState extends State<YieldDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.crop} Yield details - ${widget.district}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(context),
            const SizedBox(height: 24),
            _buildChartCard(context),
            const SizedBox(height: 24),
            _buildFeatureImportance(context),
            const SizedBox(height: 24),
            _buildSatelliteCard(context),
            const SizedBox(height: 24),
            _buildRecommendations(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(context, 'Predicted yield', '2,150 kg/ha', Icons.grass, AppTheme.primaryGreen),
                _buildStat(context, 'Confidence', '78%', Icons.verified, AppTheme.accentOrange),
                _buildStat(context, 'Last year', '1,980 kg/ha', Icons.history, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(context, 'Sowing week', '26', Icons.calendar_today, Colors.purple),
                _buildStat(context, 'Weather', 'Kharif', Icons.wb_sunny, Colors.orange),
                _buildStat(context, 'Satellite', 'Active', Icons.satellite, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildChartCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yield forecast trend', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          return SideTitleWidget(child: Text(labels[value.toInt() % 12]), axisSide: AxisSide.bottom);
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [const FlSpot(0, 1800), const FlSpot(1, 1850), const FlSpot(2, 1900), const FlSpot(3, 2000), const FlSpot(4, 2100), const FlSpot(5, 2150), const FlSpot(6, 2200), const FlSpot(7, 2180), const FlSpot(8, 2150), const FlSpot(9, 2100), const FlSpot(10, 2050), const FlSpot(11, 1950)],
                      isCurved: true,
                      color: AppTheme.primaryGreen,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: AppTheme.primaryGreen.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureImportance(BuildContext context) {
    final features = [
      {'name': 'NDVI (Satellite)', 'importance': 0.32},
      {'name': 'Soil N-P-K', 'importance': 0.24},
      {'name': 'Rainfall (Kharif)', 'importance': 0.18},
      {'name': 'Sowing week', 'importance': 0.12},
      {'name': 'Temperature', 'importance': 0.08},
      {'name': 'Humidity', 'importance': 0.06},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Key factors (SHAP)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(f['name'] as String)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: f['importance'] as double,
                      backgroundColor: Colors.grey[200],
                      color: AppTheme.primaryGreen,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${((f['importance'] as double) * 100).toInt()}%', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSatelliteCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.satellite, color: Colors.teal),
                const SizedBox(width: 8),
                Text('Satellite health indicators', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSatStat(context, 'NDVI', '0.68', 'Good vegetation health')),
                const VerticalDivider(),
                Expanded(child: _buildSatStat(context, 'EVI', '0.54', 'Enhanced vegetation index')),
                const VerticalDivider(),
                Expanded(child: _buildSatStat(context, 'Cloud cover', '12%', 'Low - reliable data')),
              ],
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(value: 0.68, color: Colors.teal, minHeight: 8),
            const SizedBox(height: 8),
            Text('NDVI: 0.68 - healthy crop, slightly above normal', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildSatStat(BuildContext context, String label, String value, String desc) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.teal)),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Text(desc, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    final recs = [
      'Strong NDVI - apply fertilizer top dressing on time',
      'Normal rainfall forecast - maintain regular irrigation',
      'Increase pest monitoring - whitefly risk during Kharif',
      'Target harvest in weeks 42-44 - market prices peak',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppTheme.accentOrange),
                const SizedBox(width: 8),
                Text('Actionable recommendations', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ...recs.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

