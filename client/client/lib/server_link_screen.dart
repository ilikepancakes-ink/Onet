import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'models.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';
import 'app_provider.dart';
import 'l10n/app_localizations.dart';

class ServerLinkScreen extends StatefulWidget {
  const ServerLinkScreen({super.key});

  @override
  _ServerLinkScreenState createState() => _ServerLinkScreenState();
}

class _ServerLinkScreenState extends State<ServerLinkScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  void _connect() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() => _isLoading = true);
    final api = ApiService(url);
    final serverInfo = await api.checkServer();
    setState(() => _isLoading = false);

    if (serverInfo != null) {
      Provider.of<AppProvider>(context, listen: false).addRecentServer(url);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthScreen(api: api, serverInfo: serverInfo),
        ),
      );
    } else {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToConnect)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appProvider = Provider.of<AppProvider>(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final scale = isMobile ? 1.5 : 1.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onetFileServer, style: TextStyle(fontSize: 20 * scale)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            iconSize: 24 * scale,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0 * scale),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: l10n.serverUrl, labelStyle: TextStyle(fontSize: 16 * scale)),
              style: TextStyle(fontSize: 16 * scale),
            ),
            SizedBox(height: 20 * scale),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _connect,
                    style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48 * scale)),
                    child: Text(l10n.connect, style: TextStyle(fontSize: 16 * scale)),
                  ),
            // Recent servers section
            if (appProvider.recentServers.isNotEmpty) ...[
              SizedBox(height: 40 * scale),
              Text(l10n.recentServers, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * scale)),
              SizedBox(height: 10 * scale),
              ...appProvider.recentServers.take(5).map((url) => SizedBox(
                height: 60 * scale,
                child: ListTile(
                  title: Text(url, style: TextStyle(fontSize: 14 * scale)),
                  onTap: () {
                    _controller.text = url;
                  },
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
