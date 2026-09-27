import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../education.dart';
import '../models.dart';
import 'theme.dart';

const _siteBase = String.fromEnvironment(
  'BULLINDICATOR_SITE_BASE',
  defaultValue: 'https://k0ini.github.io/bull-indicator',
);

class SettingsScreen extends StatelessWidget {
  final CycleData? data;
  final VoidCallback onRefresh;
  const SettingsScreen({super.key, required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: Cp.accent),
              title: const Text('Refresh data'),
              subtitle: Text(
                  data == null
                      ? 'No data loaded yet'
                      : 'Data generated ${data!.generatedAt.toLocal().toString().substring(0, 16)}',
                  style: const TextStyle(fontSize: 12)),
              onTap: onRefresh,
            ),
          ]),
        ),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.functions, color: Cp.accent),
              title: const Text('Methodology'),
              subtitle: const Text('Exactly how every score is computed',
                  style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const _TextPage(
                          title: 'Methodology', body: methodologyText))),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.source, color: Cp.accent),
              title: const Text('Data sources & attribution'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => _TextPage(
                          title: 'Data sources',
                          body: (data?.attribution ??
                                  ['Data attribution loads with market data.'])
                              .map((a) => '• $a')
                              .join('\n\n')))),
            ),
          ]),
        ),
        Card(
          child: Column(children: [
            _link(context, Icons.privacy_tip_outlined, 'Privacy policy',
                '$_siteBase/privacy.html'),
            const Divider(height: 1),
            _link(context, Icons.description_outlined, 'Terms of use',
                '$_siteBase/terms.html'),
            const Divider(height: 1),
            _link(context, Icons.support_agent, 'Support',
                '$_siteBase/support.html'),
          ]),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('About',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Cp.accent)),
                  SizedBox(height: 8),
                  Text(
                    'KŌINI Bull Indicator is an educational reference for Bitcoin market-cycle '
                    'indicators. It holds no funds, executes no trades, and gives no '
                    'financial advice. Scores describe historical context only.\n\n'
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 13.5, height: 1.5),
                  ),
                ]),
          ),
        ),
      ],
    );
  }

  Widget _link(BuildContext context, IconData icon, String title, String url) =>
      ListTile(
        leading: Icon(icon, color: Cp.accent),
        title: Text(title),
        trailing: const Icon(Icons.open_in_new, size: 16, color: Cp.textDim),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      );
}

class _TextPage extends StatelessWidget {
  final String title;
  final String body;
  const _TextPage({required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        bottomNavigationBar: const DisclaimerBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(body, style: const TextStyle(fontSize: 14.5, height: 1.6)),
        ),
      );
}
