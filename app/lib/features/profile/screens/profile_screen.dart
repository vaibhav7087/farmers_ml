import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/router.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('प्रोफाइल'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: 'सेटिंग्स',
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ProfileProvider>(
        builder: (context, auth, profile, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(context, user),
                const SizedBox(height: 24),
                _buildInfoSection(context, user),
                const SizedBox(height: 16),
                _buildCropsSection(context, user),
                const SizedBox(height: 16),
                _buildWatchedSection(context),
                const SizedBox(height: 24),
                _buildActionButtons(context, auth),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryGreen,
              child: Text(
                user.name.isNotEmpty ? user.name[0] : 'क',
                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(user.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${user.district}, ${user.state}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(context, 'फसलें', user.crops.length.toString()),
                const SizedBox(width: 12),
                _buildStatChip(context, 'देखी जा रही', '3'),
                const SizedBox(width: 12),
                _buildStatChip(context, 'अलर्ट', '5'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 18)),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('व्यक्तिगत जानकारी', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.person, 'नाम', user.name),
            _buildInfoRow(context, Icons.phone, 'फोन', user.phone.isNotEmpty ? user.phone : 'नहीं जोड़ा गया'),
            _buildInfoRow(context, Icons.location_on, 'जिला', user.district),
            _buildInfoRow(context, Icons.location_city, 'राज्य', user.state),
            _buildInfoRow(context, Icons.language, 'भाषा', _getLanguageName(user.language)),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'hi': return 'हिंदी';
      case 'mr': return 'मराठी';
      default: return 'English';
    }
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCropsSection(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('मेरी फसलें', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => _editCrops(context),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('संपादित'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.crops.map((crop) => Chip(
                label: Text(crop),
                avatar: const Icon(Icons.grass, size: 16),
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: AppTheme.primaryGreen),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _editCrops(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('फसलें संपादित करें'),
        content: const Text('यह फीचर जल्द आ रहा है। अभी प्रोफाइल सेटिंग्स से जोड़ें।'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ठीक है'))],
      ),
    );
  }

  Widget _buildWatchedSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('देखी जा रही मंडियां', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/market'),
                  child: const Text('सभी देखें'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['यवतमाळ मंडी', 'अमरावती मंडी', 'नागपुर मंडी']
                  .map((m) => Chip(
                label: Text(m),
                avatar: const Icon(Icons.store, size: 16),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: Colors.blue),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('लॉगआउट'),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}

