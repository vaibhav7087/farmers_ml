import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../profile/providers/profile_provider.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<MandiPrice> _watchedPrices = [
    MandiPrice('कपास', 'यवतमाळ मंडी', 'हाइब्रिड', 5920, 5850, '+1.2%', Icons.trending_up, Colors.green),
    MandiPrice('सोयाबीन', 'अमरावती मंडी', 'जेएस-9560', 4150, 4200, '-1.2%', Icons.trending_down, Colors.red),
    MandiPrice('मक्का', 'वर्धा मंडी', 'हाइब्रिड-25', 1850, 1830, '+1.1%', Icons.trending_up, Colors.green),
    MandiPrice('गेहूं', 'नागपुर मंडी', 'लोकवन', 2150, 2140, '+0.5%', Icons.trending_up, Colors.green),
  ];

  final List<MandiPrice> _allPrices = [
    MandiPrice('कपास', 'यवतमाळ मंडी', 'हाइब्रिड', 5920, 5850, '+1.2%', Icons.trending_up, Colors.green),
    MandiPrice('कपास', 'अमरावती मंडी', 'हाइब्रिड', 5890, 5820, '+1.2%', Icons.trending_up, Colors.green),
    MandiPrice('कपास', 'अकोला मंडी', 'देसी', 5450, 5400, '+0.9%', Icons.trending_up, Colors.green),
    MandiPrice('सोयाबीन', 'अमरावती मंडी', 'जेएस-9560', 4150, 4200, '-1.2%', Icons.trending_down, Colors.red),
    MandiPrice('सोयाबीन', 'यवतमाळ मंडी', 'जेएस-9560', 4180, 4220, '-0.9%', Icons.trending_down, Colors.red),
    MandiPrice('मक्का', 'वर्धा मंडी', 'हाइब्रिड-25', 1850, 1830, '+1.1%', Icons.trending_up, Colors.green),
    MandiPrice('मक्का', 'नागपुर मंडी', 'हाइब्रिड-30', 1870, 1850, '+1.1%', Icons.trending_up, Colors.green),
    MandiPrice('गेहूं', 'नागपुर मंडी', 'लोकवन', 2150, 2140, '+0.5%', Icons.trending_up, Colors.green),
    MandiPrice('गेहूं', 'अकोला मंडी', 'शरबती', 2200, 2180, '+0.9%', Icons.trending_up, Colors.green),
    MandiPrice('तुअर', 'यवतमाळ मंडी', 'पीडीएम-2', 6200, 6150, '+0.8%', Icons.trending_up, Colors.green),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('मंडी भाव'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'मेरी फसलें'),
            Tab(icon: Icon(Icons.list), text: 'सभी भाव'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'फिल्टर',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPrices,
            tooltip: 'रीफ्रेश',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWatchedList(),
          _buildAllPricesList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWatchedCrop,
        child: const Icon(Icons.add),
        tooltip: 'फसल जोड़ें',
      ),
    );
  }

  Widget _buildWatchedList() {
    if (_watchedPrices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('कोई फसल नहीं देखी जा रही', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('नीचे + बटन से फसलें जोड़ें', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _watchedPrices.length,
      itemBuilder: (context, index) {
        final price = _watchedPrices[index];
        return _buildPriceCard(price, isWatched: true);
      },
    );
  }

  Widget _buildAllPricesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allPrices.length,
      itemBuilder: (context, index) {
        final price = _allPrices[index];
        return _buildPriceCard(price);
      },
    );
  }

  Widget _buildPriceCard(MandiPrice price, {bool isWatched = false}) {
    final change = double.tryParse(price.change.replaceAll('%', '')) ?? 0;
    final isUp = change >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.grass, color: AppTheme.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(price.crop, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text('${price.variety} • ${price.mandi}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                ),
                if (isWatched)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text('देखा जा रहा', style: TextStyle(color: Colors.amber[800], fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('वर्तमान भाव', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                      Text('₹${price.currentPrice}/क्विंटल', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('पिछला भाव', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                      Text('₹${price.previousPrice}/क्विंटल', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(price.icon, color: isUp ? Colors.green : Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${price.change} परिवर्तन',
                    style: TextStyle(color: isUp ? Colors.green : Colors.red, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshPrices() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('भाव रीफ्रेश हो रहे हैं...'), duration: Duration(seconds: 1)),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('भाव अपडेट हो गए'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('फिल्टर'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('फसल चुनें:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['कपास', 'सोयाबीन', 'मक्का', 'गेहूं', 'चावल', 'तुअर']
                  .map((c) => FilterChip(label: Text(c), selected: false, onSelected: (_) {}))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('रद्द')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('लागू करें')),
        ],
      ),
    );
  }

  void _addWatchedCrop() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('फसल जोड़ें'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'फसल'),
              items: ['कपास', 'सोयाबीन', 'मक्का', 'गेहूं', 'चावल', 'तुअर']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {},
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'मंडी'),
              items: ['यवतमाळ मंडी', 'अमरावती मंडी', 'अकोला मंडी', 'वर्धा मंडी', 'नागपुर मंडी']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {},
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'किस्म'),
              items: ['हाइब्रिड', 'देसी', 'उन्नत']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('रद्द')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('जोड़ें')),
        ],
      ),
    );
  }
}

class MandiPrice {
  final String crop;
  final String mandi;
  final String variety;
  final int currentPrice;
  final int previousPrice;
  final String change;
  final IconData icon;
  final Color color;

  MandiPrice(this.crop, this.mandi, this.variety, this.currentPrice, this.previousPrice, this.change, this.icon, this.color);
}

