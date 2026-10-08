import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../providers/advisory_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AdvisoryScreen extends StatefulWidget {
  const AdvisoryScreen({super.key});

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  String _selectedCrop = 'कपास';
  String _selectedDistrict = 'यवतमाळ';
  String _selectedMandi = 'यवतमाळ मंडी';
  String? _selectedVariety;
  int _sowingWeek = 26;
  bool _useSatellite = true;

  final List<String> _crops = ['कपास', 'सोयाबीन', 'मक्का', 'गेहूं', 'चावल', 'तुअर'];
  final List<String> _districts = ['यवतमाळ', 'अमरावती', 'अकोला', 'वर्धा', 'नागपुर'];
  final List<String> _mandis = ['यवतमाळ मंडी', 'अमरावती मंडी', 'अकोला मंडी', 'वर्धा मंडी', 'नागपुर मंडी'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('फसल सलाह'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdvisory,
            tooltip: 'सलाह रीफ्रेश करें',
          ),
        ],
      ),
      body: Consumer<AdvisoryProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputCard(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 24),
                if (provider.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else if (provider.error != null)
                  _buildErrorCard(provider.error!)
                else if (provider.currentAdvisory != null)
                  _buildAdvisoryResult(provider.currentAdvisory!),
              ],
            ),
          ),
        },
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('अपनी फसल और स्थान चुनें', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCrop,
                    decoration: const InputDecoration(labelText: 'फसल', prefixIcon: Icon(Icons.grass)),
                    items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCrop = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    decoration: const InputDecoration(labelText: 'जिला', prefixIcon: Icon(Icons.location_on)),
                    items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setState(() => _selectedDistrict = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMandi,
                    decoration: const InputDecoration(labelText: 'मंडी', prefixIcon: Icon(Icons.store)),
                    items: _mandis.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _selectedMandi = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedVariety,
                    decoration: const InputDecoration(labelText: 'किस्म (वैकल्पिक)', prefixIcon: Icon(Icons.category)),
                    items: ['हाइब्रिड', 'देसी', 'उन्नत'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setState(() => _selectedVariety = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _sowingWeek,
                    decoration: const InputDecoration(labelText: 'बुवाई सप्ताह', prefixIcon: Icon(Icons.calendar_today)),
                    items: List.generate(52, (i) => i + 1).map((w) => DropdownMenuItem(value: w, child: Text('सप्ताह $w'))).toList(),
                    onChanged: (v) => setState(() => _sowingWeek = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('सैटेलाइट डेटा'),
                    value: true,
                    onChanged: (v) {},
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.grass),
            label: const Text('उपज पूर्वानुमान'),
            onPressed: () => _loadYieldOnly(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.trending_up),
            label: const Text('भाव पूर्वानुमान'),
            onPressed: () => _loadPriceOnly(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisoryResult(data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('सलाह सारांश', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard('उपज पूर्वानुमान', '${data.predictedYield.toInt()} kg/ha', Icons.grass, AppTheme.primaryGreen)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('भाव पूर्वानुमान', '₹${data.predictedPrice.toInt()}/क्विंटल', Icons.trending_up, AppTheme.accentOrange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('कुल राजस्व', '₹${data.grossRevenue.toInt()}/हेक्टेयर', Icons.currency_rupee, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('शुद्ध लाभ', '₹${data.netProfit.toInt()}/हेक्टेयर', Icons.savings, Colors.green)),
          ],
        ),
        const SizedBox(height: 24),
        Text('सिफारिशें', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...data.recommendations.map((r) => Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(r),
          ),
        )),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.grass),
                label: const Text('उपज विवरण'),
                onPressed: () => context.go('/advisory/yield/$_selectedDistrict/$_selectedCrop'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.trending_up),
                label: const Text('भाव विवरण'),
                onPressed: () => context.go('/advisory/price/$_selectedMandi/$_selectedCrop'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('अंतिम अपडेट: ${data.generatedAt.toLocal().toString().substring(0, 19)}', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color)),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAdvisory() async {
    final provider = context.read<AdvisoryProvider>();
    await provider.fetchAdvisory(
      district: _selectedDistrict,
      crop: _selectedCrop,
      mandi: _selectedMandi,
      variety: _selectedVariety,
      sowingWeek: _sowingWeek,
    );
  }

  Future<void> _loadYieldOnly() async {
    final provider = context.read<AdvisoryProvider>();
    await provider.fetchYieldPrediction(
      district: _selectedDistrict,
      crop: _selectedCrop,
      sowingWeek: _sowingWeek,
      useSatellite: true,
    );
  }

  Future<void> _loadPriceOnly() async {
    final provider = context.read<AdvisoryProvider>();
    await provider.fetchPricePrediction(
      mandi: _selectedMandi,
      crop: _selectedCrop,
      variety: _selectedVariety,
      horizonDays: 14,
      includePolicy: true,
    );
  }
}