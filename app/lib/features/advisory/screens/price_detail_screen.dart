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
        title: Text('$crop भाव विवरण - $mandi'),
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
                _buildStat(context, 'वर्तमान भाव', '₹5,850/क्विंटल', Icons.currency_rupee, AppTheme.primaryGreen),
                _buildStat(context, '14-दिन पूर्वानुमान', '₹6,120/क्विंटल', Icons.trending_up, AppTheme.accentOrange),
                _buildStat(context, 'आत्मविश्वास', '72%', Icons.verified, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(context, 'साप्ताहिक परिवर्तन', '+4.6%', Icons.percent, Colors.green),
                _buildStat(context, 'मासिक परिवर्तन', '+8.2%', Icons.show_chart, Colors.green),
                _buildStat(context, 'नीति प्रभाव', '+₹270', Icons.gavel, AppTheme.accentOrange),
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
                Text('भाव प्रवृत्ति (14 दिन)', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('नीति प्रभाव शामिल', style: TextStyle(color: AppTheme.accentOrange, fontSize: 12, fontWeight: FontWeight.w600)),
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
                          const days = ['आज', '2', '4', '6', '8', '10', '12', '14'];
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
                _buildLegend(context, AppTheme.accentOrange, 'नीति-समायोजित पूर्वानुमान'),
                const SizedBox(width: 24),
                _buildLegend(context, Colors.grey[400]!, 'बेसलाइन (कोई नीति नहीं)'),
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
                Text('नीति घटनाएं (भाव प्रभाव)', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildPolicyItem(context, 'MSP वृद्धि घोषणा', '+₹270/क्विंटल', 'केंद्र सरकार ने कपास MSP ₹7,200 से ₹7,470 किया', '2 दिन पहले'),
            _buildPolicyItem(context, 'निर्यात प्रतिबंध हटाया', '+₹150/क्विंटल', 'कपास निर्यात पर प्रतिबंध हटाया गया', '1 सप्ताह पहले'),
            _buildPolicyItem(context, 'खरीद लक्ष्य बढ़ाया', '+₹120/क्विंटल', 'CCI खरीद लक्ष्य 25% बढ़ाया', '3 दिन पहले'),
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
            Text('ट्रेडिंग सिग्नल', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildSignal(context, 'खरीदें / होल्ड करें', 'भाव ऊपर की ओर - 14 दिन में +4.6% अपेक्षित', Icons.trending_up, Colors.green),
            _buildSignal(context, 'बेचने में जल्दी न करें', 'नीति समर्थन मजबूत - MSP + निर्यात खुला', Icons.shield, Colors.blue),
            _buildSignal(context, 'दूसरे सप्ताह नजर रखें', 'सप्ताह 2 में मामूली सुधार संभव', Icons.visibility, AppTheme.accentOrange),
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
                Text('कार्रवाई योजना', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionWeek(context, 'सप्ताह 1 (आज-7 दिन)', 'होल्ड करें - भाव चढ़ रहा है', 'बिक्री न करें', Colors.green),
            _buildActionWeek(context, 'सप्ताह 2 (8-14 दिन)', 'बाजार नजर रखें - मामूली सुधार संभव', 'आंशिक बिक्री पर विचार', AppTheme.accentOrange),
            _buildActionWeek(context, 'सप्ताह 3-4', 'नीति अपडेट जांचें - MCI खरीद शुरू', 'तैयार रहें', Colors.blue),
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

