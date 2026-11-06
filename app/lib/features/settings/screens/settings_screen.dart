import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../profile/providers/profile_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<ProfileProvider>(
        builder: (context, profile, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(context, 'Language and region', [
                _buildLanguageTile(context, profile),
                _buildRegionTile(context, profile),
              ]),
              const SizedBox(height: 24),
              _buildSection(context, 'Notifications', [
                _buildNotificationTile(context, profile),
                _buildAlertPreferencesTile(context),
              ]),
              const SizedBox(height: 24),
              _buildSection(context, 'Appearance', [
                _buildThemeTile(context, profile),
              ]),
              const SizedBox(height: 24),
              _buildSection(context, 'Data and privacy', [
                _buildDataUsageTile(context),
                _buildCacheTile(context),
                _buildExportTile(context),
                _buildDeleteTile(context),
              ]),
              const SizedBox(height: 24),
              _buildSection(context, 'About the app', [
                _buildVersionTile(context),
                _buildLicenseTile(context),
                _buildSupportTile(context),
              ]),
              const SizedBox(height: 32),
              _buildLogoutButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, ProfileProvider profile) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Language'),
      subtitle: Text(_getLanguageName(profile.preferredLanguage)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context, profile),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'hi': return 'Hindi';
      case 'mr': return 'Marathi';
      default: return 'English';
    }
  }

  void _showLanguageDialog(BuildContext context, ProfileProvider profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(title: const Text('Hindi'), value: 'hi', groupValue: profile.preferredLanguage, onChanged: (v) => profile.setLanguage(v!)),
            RadioListTile<String>(title: const Text('Marathi'), value: 'mr', groupValue: profile.preferredLanguage, onChanged: (v) => profile.setLanguage(v!)),
            RadioListTile<String>(title: const Text('English'), value: 'en', groupValue: profile.preferredLanguage, onChanged: (v) => profile.setLanguage(v!)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Widget _buildRegionTile(BuildContext context, ProfileProvider profile) {
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: const Text('Region / state'),
      subtitle: const Text('Maharashtra (default)'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _buildNotificationTile(BuildContext context, ProfileProvider profile) {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications),
      title: const Text('Push notifications'),
      subtitle: const Text('Price alerts, weather warnings and outbreak notifications'),
      value: profile.notificationsEnabled,
      onChanged: (v) => profile.toggleNotifications(v),
      activeColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildAlertPreferencesTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('Alert preferences'),
      subtitle: const Text('Choose which alerts to receive'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showAlertPreferencesDialog(context),
    );
  }

  void _showAlertPreferencesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert preferences'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(title: const Text('Price alerts'), value: true, onChanged: (_) {}),
            SwitchListTile(title: const Text('Weather warnings'), value: true, onChanged: (_) {}),
            SwitchListTile(title: const Text('Pest / disease outbreaks'), value: true, onChanged: (_) {}),
            SwitchListTile(title: const Text('Policy announcements'), value: false, onChanged: (_) {}),
            SwitchListTile(title: const Text('Weekly summary'), value: true, onChanged: (_) {}),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Save'))],
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, ProfileProvider profile) {
    return SwitchListTile(
      secondary: const Icon(Icons.dark_mode),
      title: const Text('Dark mode'),
      subtitle: const Text('Easier on the eyes at night'),
      value: profile.darkMode,
      onChanged: (v) => profile.toggleDarkMode(v),
      activeColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildDataUsageTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('Data usage'),
      subtitle: const Text('Cache: 12.4 MB • Offline data: 4.2 MB'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showDataUsageDialog(context),
    );
  }

  void _showDataUsageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data usage details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.cached), title: const Text('API Cache'), trailing: const Text('12.4 MB')),
            ListTile(leading: const Icon(Icons.download_for_offline), title: const Text('Offline advisory'), trailing: const Text('4.2 MB')),
            ListTile(leading: const Icon(Icons.image), title: const Text('Satellite images'), trailing: const Text('8.7 MB')),
            const Divider(),
            ListTile(leading: const Icon(Icons.pie_chart), title: const Text('Total'), trailing: const Text('25.3 MB', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _clearCache(context); }, child: const Text('Clear cache')),
        ],
      ),
    );
  }

  void _clearCache(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clearing cache...')));
  }

  Widget _buildCacheTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.cleaning_services),
      title: const Text('Clear cache'),
      subtitle: const Text('Remove temporary files to free up storage'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _clearCache(context),
    );
  }

  Widget _buildExportTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.download),
      title: const Text('Export data'),
      subtitle: const Text('Download your profile, crops and history'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _exportData(context),
    );
  }

  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing export...')));
  }

  Widget _buildDeleteTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('Delete account', style: TextStyle(color: Colors.red)),
      subtitle: const Text('Permanently delete all data'),
      onTap: () => _showDeleteConfirmation(context),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This action cannot be undone. All data will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.of(context).pushNamed('/login'); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('App version'),
      subtitle: const Text('1.0.0+1 (Build 1)'),
      trailing: const Text('Latest'),
    );
  }

  Widget _buildLicenseTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.description),
      title: const Text('Open source licenses'),
      subtitle: const Text('View third-party licenses'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLicensesDialog(context),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showLicensePage(context: context, applicationName: 'Kisaan-ML', applicationVersion: '1.0.0+1');
  }

  Widget _buildSupportTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.help_outline),
      title: const Text('Help and feedback'),
      subtitle: const Text('Report a problem or share a suggestion'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showSupportDialog(context),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Email: support@kisaan-ml.in'),
            const SizedBox(height: 8),
            const Text('WhatsApp: +91-98765-43210'),
            const SizedBox(height: 8),
            const Text('GitHub: github.com/kisaan-ml/issues'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Log out'),
        onPressed: () => context.go('/login'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

