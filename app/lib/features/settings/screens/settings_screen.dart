import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../features/profile/providers/profile_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('सेटिंग्स')),
      body: Consumer<ProfileProvider>(
        builder: (context, profile, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection('भाषा और क्षेत्र', [
                _buildLanguageTile(profile),
                _buildRegionTile(profile),
              ]),
              const SizedBox(height: 24),
              _buildSection('सूचनाएं', [
                _buildNotificationTile(profile),
                _buildAlertPreferencesTile(),
              ]),
              const SizedBox(height: 24),
              _buildSection('दिखावट', [
                _buildThemeTile(profile),
              ]),
              const SizedBox(height: 24),
              _buildSection('डेटा और गोपनीयता', [
                _buildDataUsageTile(),
                _buildCacheTile(),
                _buildExportTile(),
                _buildDeleteTile(),
              ]),
              const SizedBox(height: 24),
              _buildSection('ऐप के बारे में', [
                _buildVersionTile(),
                _buildLicenseTile(),
                _buildSupportTile(),
              ]),
              const SizedBox(height: 32),
              _buildLogoutButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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

  Widget _buildLanguageTile(ProfileProvider profile) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('भाषा'),
      subtitle: Text(_getLanguageName(profile.preferredLanguage)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context, profile),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'hi': return 'हिंदी';
      case 'mr': return 'मराठी';
      default: return 'English';
    }
  }

  void _showLanguageDialog(BuildContext context, ProfileProvider profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('भाषा चुनें'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(title: const Text('हिंदी'), value: 'hi', groupValue: profile.preferredLanguage, onChanged: (v) => profile.setLanguage(v!)),
            RadioListTile<String>(title: const Text('मराठी'), value: 'mr', groupValue: profile.preferredLanguage, onChanged: (v) => profile.setLanguage(v!)),
            RadioListTile<String>(title: const Text('English'), value: 'en', groupValue: profile.preferredLanguage, onChanged: (v) => profile.setLanguage(v!)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ठीक है'))],
      ),
    );
  }

  Widget _buildRegionTile(ProfileProvider profile) {
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: const Text('क्षेत्र/राज्य'),
      subtitle: const Text('महाराष्ट्र (डिफॉल्ट)'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _buildNotificationTile(ProfileProvider profile) {
    return SwitchListTile(
      leading: const Icon(Icons.notifications),
      title: const Text('पुश सूचनाएं'),
      subtitle: const Text('भाव अलर्ट, मौसम चेतावनी, प्रकोप सूचनाएं'),
      value: profile.notificationsEnabled,
      onChanged: (v) => profile.toggleNotifications(v),
      activeColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildAlertPreferencesTile() {
    return ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('अलर्ट प्राथमिकताएं'),
      subtitle: const Text('कौन से अलर्ट प्राप्त करें'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showAlertPreferencesDialog(context),
    );
  }

  void _showAlertPreferencesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('अलर्ट प्राथमिकताएं'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(title: const Text('भाव अलर्ट'), value: true, onChanged: (_) {}),
            SwitchListTile(title: const Text('मौसम चेतावनी'), value: true, onChanged: (_) {}),
            SwitchListTile(title: const Text('कीट/रोग प्रकोप'), value: true, onChanged: (_) {}),
            SwitchListTile(title: const Text('नीति घोषणाएं'), value: false, onChanged: (_) {}),
            SwitchListTile(title: const Text('साप्ताहिक सारांश'), value: true, onChanged: (_) {}),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('सहेजें'))],
      ),
    );
  }

  Widget _buildThemeTile(ProfileProvider profile) {
    return SwitchListTile(
      leading: const Icon(Icons.dark_mode),
      title: const Text('डार्क मोड'),
      subtitle: const Text('रात में आंखों के लिए आरामदायक'),
      value: profile.darkMode,
      onChanged: (v) => profile.toggleDarkMode(v),
      activeColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildDataUsageTile() {
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('डेटा उपयोग'),
      subtitle: const Text('कैश: 12.4 MB • ऑफलाइन डेटा: 4.2 MB'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showDataUsageDialog(context),
    );
  }

  void _showDataUsageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('डेटा उपयोग विवरण'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.cached), title: const Text('API कैश'), trailing: const Text('12.4 MB')),
            ListTile(leading: const Icon(Icons.download_for_offline), title: const Text('ऑफलाइन सलाह'), trailing: const Text('4.2 MB')),
            ListTile(leading: const Icon(Icons.image), title: const Text('सैटेलाइट इमेज'), trailing: const Text('8.7 MB')),
            const Divider(),
            ListTile(leading: const Icon(Icons.pie_chart), title: const Text('कुल'), trailing: const Text('25.3 MB', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('बंद करें')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _clearCache(context); }, child: const Text('कैश साफ करें')),
        ],
      ),
    );
  }

  void _clearCache(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कैश साफ किया जा रहा है...')));
  }

  Widget _buildCacheTile() {
    return ListTile(
      leading: const Icon(Icons.cleaning_services),
      title: const Text('कैश साफ करें'),
      subtitle: const Text('अस्थाई फाइलें हटाकर स्टोरेज खाली करें'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _clearCache(context),
    );
  }

  Widget _buildExportTile() {
    return ListTile(
      leading: const Icon(Icons.download),
      title: const Text('डेटा निर्यात करें'),
      subtitle: const Text('अपनी प्रोफाइल, फसलें, और इतिहास डाउनलोड करें'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _exportData(context),
    );
  }

  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('निर्यात तैयार हो रहा है...')));
  }

  Widget _buildDeleteTile() {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('खाता हटाएं', style: TextStyle(color: Colors.red)),
      subtitle: const Text('स्थायी रूप से सभी डेटा मिटाएं'),
      onTap: () => _showDeleteConfirmation(context),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('खाता हटाएं?'),
        content: const Text('यह कार्रवाई पूर्ववत नहीं की जा सकती। सभी डेटा स्थायी रूप से मिट जाएगा।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('रद्द')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.of(context).pushNamed('/login'); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('हटाएं'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionTile() {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('ऐप संस्करण'),
      subtitle: const Text('1.0.0+1 (Build 1)'),
      trailing: const Text('नवीनतम'),
    );
  }

  Widget _buildLicenseTile() {
    return ListTile(
      leading: const Icon(Icons.description),
      title: const Text('ओपन सोर्स लाइसेंस'),
      subtitle: const Text('थर्ड-पार्टी लाइसेंस देखें'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLicensesDialog(context),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showLicensePage(context: context, applicationName: 'Kisaan-ML', applicationVersion: '1.0.0+1');
  }

  Widget _buildSupportTile() {
    return ListTile(
      leading: const Icon(Icons.help_outline),
      title: const Text('सहायता और प्रतिक्रिया'),
      subtitle: const Text('समस्या रिपोर्ट करें या सुझाव दें'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showSupportDialog(context),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('सहायता'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ईमेल: support@kisaan-ml.in'),
            const SizedBox(height: 8),
            const Text('WhatsApp: +91-98765-43210'),
            const SizedBox(height: 8),
            const Text('GitHub: github.com/kisaan-ml/issues'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('बंद करें'))],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('लॉगआउट'),
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