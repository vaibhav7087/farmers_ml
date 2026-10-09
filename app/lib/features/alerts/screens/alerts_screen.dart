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
    AlertItem('Cotton price alert', 'Cotton exceeds ₹5,900 at Yavatmal Mandi', '₹5,920 current', Icons.trending_up, Colors.green, '5 minutes ago'),
    AlertItem('Soybean price drop', 'Soybean falls below ₹4,200 at Amravati', '₹4,150 current', Icons.trending_down, Colors.red, '15 minutes ago'),
    AlertItem('MSP announcement', 'Cotton MSP announced at ₹7,470', '+₹270 from the previous price', Icons.gavel, AppTheme.accentOrange, '1 hour ago'),
  ];

  final List<AlertItem> _weatherAlerts = [
    AlertItem('Heavy rainfall warning', 'Heavy rain expected in Yavatmal over the next 48 hours', 'IMD red alert', Icons.cloud, Colors.blue, '30 minutes ago'),
    AlertItem('Temperature drop', 'Night temperature may drop to 12°C', 'Take measures to protect crops', Icons.thermostat, AppTheme.accentOrange, '2 hours ago'),
  ];

  final List<AlertItem> _outbreakAlerts = [
    AlertItem('Pink bollworm outbreak', 'Reported in 12 villages in Yavatmal', 'Spray immediately', Icons.bug_report, Colors.red, '3 hours ago'),
    AlertItem('Whitefly spread', '23% increase in Amravati district', 'Spray neem oil', Icons.bug_report, AppTheme.accentOrange, '5 hours ago'),
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
        title: const Text('Alerts and warnings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.currency_rupee), text: 'Prices'),
            Tab(icon: Icon(Icons.cloud), text: 'Weather'),
            Tab(icon: Icon(Icons.bug_report), text: 'Outbreaks'),
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
            Text('No alerts', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('New alerts will appear here', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
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
            Text('Current value: ${alert.value}', style: TextStyle(color: alert.color, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Time: ${alert.time}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
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

