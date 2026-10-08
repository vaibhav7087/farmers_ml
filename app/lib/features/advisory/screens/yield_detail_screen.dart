import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../core/router.dart';

class YieldDetailScreen extends StatelessWidget {
  final String district;
  final String crop;

  const YieldDetailScreen({super.key, required this.district, required this.crop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$crop उपज विवरण - $district'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildChartCard(),
            const SizedBox(height: 24),
            _buildFeatureImportance(),
            const SizedBox(height: 24),
            _buildSatelliteCard(),
            const SizedBox(height: 24),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('पूर्वानुमानित उपज', '2,150 kg/ha', Icons.grass, AppTheme.primaryGreen),
                _buildStat('आत्मविश्वास', '78%', Icons.verified, AppTheme.accentOrange),
                _buildStat('पिछले साल', '1,980 kg/ha', Icons.history, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('बुवाई सप्ताह', '26', Icons.calendar_today, Colors.purple),
                _buildStat('मौसम', 'खरीफ', Icons.wb_sunny, Colors.orange),
                _buildStat('सैटेलाइट', 'सक्रिय', Icons.satellite, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
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

  Widget _buildChartCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('उपज पूर्वानुमान प्रवृत्ति', style: Theme.of(context).textTheme.titleMedium),
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
                          const labels = ['जन', 'फर', 'मार', 'अप्र', 'मई', 'जून', 'जुल', 'अग', 'सित', 'अक्ट', 'नव', 'दिस'];
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

  Widget _buildFeatureImportance() {
    final features = [
      {'name': 'NDVI (सैटेलाइट)', 'importance': 0.32},
      {'name': 'मिट्टी N-P-K', 'importance': 0.24},
      {'name': 'वर्षा (खरीफ)', 'importance': 0.18},
      {'name': 'बुवाई सप्ताह', 'importance': 0.12},
      {'name': 'तापमान', 'importance': 0.08},
      {'name': 'आर्द्रता', 'importance': 0.06},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('महत्वपूर्ण कारक (SHAP)', style: Theme.of(context).textTheme.titleMedium),
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
                  Text('${(f['importance'] as double * 100).toInt()}%', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSatelliteCard() {
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
                Text('सैटेलाइट स्वास्थ्य सूचकांक', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSatStat('NDVI', '0.68', 'अच्छा वनस्पति स्वास्थ्य')),
                const VerticalDivider(),
                Expanded(child: _buildSatStat('EVI', '0.54', 'उन्नत वनस्पति सूचकांक')),
                const VerticalDivider(),
                Expanded(child: _buildSatStat('बादल कवर', '12%', 'कम - विश्वसनीय डेटा')),
              ],
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(value: 0.68, color: Colors.teal, minHeight: 8),
            const SizedBox(height: 8),
            Text('NDVI: 0.68 - फसल स्वस्थ है, सामान्य से थोड़ा ऊपर', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildSatStat(String label, String value, String desc) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.teal)),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Text(desc, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildRecommendations() {
    final recs = [
      'NDVI मजबूत है - उर्वरक टॉप-ड्रेसिंग समय पर करें',
      'वर्षा पूर्वानुमान सामान्य - सिंचाई योजना सामान्य रखें',
      'कीट निगरानी बढ़ाएं - खरीफ में सफेद मक्खी का जोखिम',
      'कटाई सप्ताह 42-44 लक्ष्य रखें - बाजार भाव चरम पर',
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
                Text('कार्रवाई योग्य सिफारिशें', style: Theme.of(context).textTheme.titleMedium),
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