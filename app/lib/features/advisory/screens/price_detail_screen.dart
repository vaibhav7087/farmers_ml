import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';

class PriceDetailScreen extends StatelessWidget {
  final String mandi;
  final String crop;
  final String? variety;

  const PriceDetailScreen({super.key, required this.mandi, required this.crop, this.variety});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$crop Price details - $mandi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(context),
            const SizedBox(height: 24),
            _buildPriceChart(context),
            const SizedBox(height: 24),
            _buildPolicyCard(context),
            const SizedBox(height: 24),
            _buildTradingSignals(context),
            const SizedBox(height: 24),
            _buildActionPlan(context),
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
                _buildStat(context, 'Current price', '₹5,850/quintal', Icons.currency_rupee, AppTheme.primaryGreen),
                _buildStat(context, '14-day forecast', '₹6,120/quintal', Icons.trending_up, AppTheme.accentOrange),
                _buildStat(context, 'Confidence', '72%', Icons.verified, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(context, 'Weekly change', '+4.6%', Icons.percent, Colors.green),
                _buildStat(context, 'Monthly change', '+8.2%', Icons.show_chart, Colors.green),
                _buildStat(context, 'Policy impact', '+₹270', Icons.gavel, AppTheme.accentOrange),
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

  Widget _buildPriceChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Price trend (14 days)', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('Includes policy impact', style: TextStyle(color: AppTheme.accentOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Today', '2', '4', '6', '8', '10', '12', '14'];
                          return SideTitleWidget(child: Text(days[value.toInt() % 8]), axisSide: AxisSide.bottom);
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [const FlSpot(0, 5850), const FlSpot(1, 5900), const FlSpot(2, 5950), const FlSpot(3, 6000), const FlSpot(4, 6050), const FlSpot(5, 6100), const FlSpot(6, 6120), const FlSpot(7, 6100), const FlSpot(8, 6080), const FlSpot(9, 6090), const FlSpot(10, 6100), const FlSpot(11, 6110), const FlSpot(12, 6115), const FlSpot(13, 6120)],
                      isCurved: true,
                      color: AppTheme.accentOrange,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: AppTheme.accentOrange.withValues(alpha: 0.1)),
                    ),
                    LineChartBarData(
                      spots: [const FlSpot(0, 5850), const FlSpot(1, 5870), const FlSpot(2, 5890), const FlSpot(3, 5920), const FlSpot(4, 5950), const FlSpot(5, 5970), const FlSpot(6, 5980), const FlSpot(7, 5990), const FlSpot(8, 5995), const FlSpot(9, 6000), const FlSpot(10, 6010), const FlSpot(11, 6015), const FlSpot(12, 6020), const FlSpot(13, 6025)],
                      isCurved: true,
                      color: Colors.grey[400]!,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(context, AppTheme.accentOrange, 'Policy-adjusted forecast'),
                const SizedBox(width: 24),
                _buildLegend(context, Colors.grey[400]!, 'Baseline (no policy)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPolicyCard(BuildContext context) {
    return Card(
      color: AppTheme.accentOrange.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, color: AppTheme.accentOrange),
                const SizedBox(width: 8),
                Text('Policy events (price impact)', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildPolicyItem(context, 'MSP increase announced', '+₹270/quintal', 'The government raised cotton MSP from ₹7,200 to ₹7,470', '2 days ago'),
            _buildPolicyItem(context, 'Export ban lifted', '+₹150/quintal', 'The cotton export ban was lifted', '1 week ago'),
            _buildPolicyItem(context, 'Procurement target increased', '+₹120/quintal', 'CCI procurement target increased by 25%', '3 days ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem(BuildContext context, String title, String impact, String desc, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Icons.gavel, color: AppTheme.accentOrange, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(impact, style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(desc, style: Theme.of(context).textTheme.bodySmall),
                Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingSignals(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trading signals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildSignal(context, 'Buy / hold', 'Prices trending up - +4.6% expected in 14 days', Icons.trending_up, Colors.green),
            _buildSignal(context, 'Avoid rushing to sell', 'Strong policy support - MSP and open exports', Icons.shield, Colors.blue),
            _buildSignal(context, 'Monitor the second week', 'A small correction is possible in week 2', Icons.visibility, AppTheme.accentOrange),
          ],
        ),
      ),
    );
  }

  Widget _buildSignal(BuildContext context, String title, String desc, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                Text(desc, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPlan(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text('Action plan', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionWeek(context, 'Week 1 (today to day 7)', 'Hold - prices are rising', 'Do not sell', Colors.green),
            _buildActionWeek(context, 'Week 2 (days 8-14)', 'Monitor the market - a small correction is possible', 'Consider a partial sale', AppTheme.accentOrange),
            _buildActionWeek(context, 'Week 3-4', 'Check policy updates - MCI procurement begins', 'Be prepared', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildActionWeek(BuildContext context, String week, String action, String detail, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(week, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                Text(action, style: Theme.of(context).textTheme.bodyMedium),
                Text(detail, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

