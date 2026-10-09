import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../profile/providers/profile_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<AlertItem> _priceAlerts = [
    AlertItem('कपास भाव चेतावनी', 'यवतमाळ मंडी में कपास ₹5,900 पार', '₹5,920 वर्तमान', Icons.trending_up, Colors.green, '5 मिनट पहले'),
    AlertItem('सोयाबीन गिरावट', 'अमरावती में सोयाबीन ₹4,200 नीचे', '₹4,150 वर्तमान', Icons.trending_down, Colors.red, '15 मिनट पहले'),
    AlertItem('MSP घोषणा', 'कपास MSP ₹7,470 घोषित', 'पिछले भाव से +₹270', Icons.gavel, AppTheme.accentOrange, '1 घंटा पहले'),
  ];

  final List<AlertItem> _weatherAlerts = [
    AlertItem('भारी वर्षा चेतावनी', 'यवतमाळ में अगले 48 घंटे भारी वर्षा', 'IMD रेड अलर्ट', Icons.cloud, Colors.blue, '30 मिनट पहले'),
    AlertItem('तापमान गिरावट', 'रात का तापमान 12°C तक गिर सकता है', 'फसल सुरक्षा उपाय करें', Icons.thermostat, AppTheme.accentOrange, '2 घंटे पहले'),
  ];

  final List<AlertItem> _outbreakAlerts = [
    AlertItem('गुलाबी सुंडी प्रकोप', 'यवतमाळ के 12 गांवों में पाया गया', 'तत्काल स्प्रे करें', Icons.bug_report, Colors.red, '3 घंटे पहले'),
    AlertItem('सफेद मक्खी फैलाव', 'अमरावती जिले में 23% वृद्धि', 'नीम तेल स्प्रे करें', Icons.bug_report, AppTheme.accentOrange, '5 घंटे पहले'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('अलर्ट और चेतावनियां'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.currency_rupee), text: 'भाव'),
            Tab(icon: Icon(Icons.cloud), text: 'मौसम'),
            Tab(icon: Icon(Icons.bug_report), text: 'प्रकोप'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertList(_priceAlerts),
          _buildAlertList(_weatherAlerts),
          _buildAlertList(_outbreakAlerts),
        ],
      ),
    );
  }

  Widget _buildAlertList(List<AlertItem> alerts) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('कोई अलर्ट नहीं', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('जब कोई अलर्ट आएगा तो यहां दिखेगा', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: alert.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(alert.icon, color: alert.color, size: 24),
            ),
            title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.subtitle),
                const SizedBox(height: 4),
                Text(alert.time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
            trailing: Text(alert.value, style: TextStyle(color: alert.color, fontWeight: FontWeight.bold)),
            onTap: () => _showAlertDetail(context, alert),
          ),
        );
      },
    );
  }

  void _showAlertDetail(BuildContext context, AlertItem alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: alert.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(alert.icon, color: alert.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(alert.title, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 16),
            Text(alert.subtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('वर्तमान मूल्य: ${alert.value}', style: TextStyle(color: alert.color, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('समय: ${alert.time}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ठीक है'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertItem {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final String time;

  AlertItem(this.title, this.subtitle, this.value, this.icon, this.color, this.time);
}

