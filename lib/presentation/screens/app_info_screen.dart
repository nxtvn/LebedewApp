import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/privacy_policy_screen.dart';

/// Bildschirm zur Anzeige der App-Metadaten
///
/// Dieser Bildschirm zeigt Informationen über die App an, wie z.B.
/// Versionsnummer, Entwickler-Kontakt, Support-URL und Datenschutzhinweis-Link.
class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({Key? key}) : super(key: key);

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Lebedew App',
    packageName: 'de.lebedew.app',
    version: '1.0.0',
    buildNumber: '1',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konnte die URL nicht öffnen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App-Informationen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Image.asset(
                  'assets/logo.png',
                  height: 100,
                  semanticLabel: 'Lebedew Logo',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoSection('App-Version', '${_packageInfo.version} (Build ${_packageInfo.buildNumber})'),
            const Divider(),
            _buildInfoSection('Entwickelt von', 'Lebedew Haustechnik GmbH'),
            const Divider(),
            _buildInfoSection('Kontakt', 'info@lebedew.de'),
            const Divider(),
            _buildClickableSection(
              'Support',
              'https://www.lebedew.de/support',
              onTap: () => _launchURL('https://www.lebedew.de/support'),
            ),
            const Divider(),
            _buildClickableSection(
              'Datenschutzhinweis',
              'Datenschutzrichtlinien anzeigen',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildClickableSection(
              'Website',
              'https://www.lebedew.de',
              onTap: () => _launchURL('https://www.lebedew.de'),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                '© 2023-2024 Lebedew Haustechnik GmbH\nAlle Rechte vorbehalten.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableSection(String title, String content, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 