import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'models.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';
import 'app_provider.dart';
import 'l10n/app_localizations.dart';

class ServerLinkScreen extends StatefulWidget {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onetFileServer),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: l10n.serverUrl),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _connect,
                    child: Text(l10n.connect),
                  ),
            // Recent servers section
            if (appProvider.recentServers.isNotEmpty) ...[
              SizedBox(height: 40),
              Text(l10n.recentServers, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...appProvider.recentServers.take(5).map((url) => ListTile(
                title: Text(url),
                onTap: () {
                  _controller.text = url;
                },
              )),
            ],
          ],
        ),
      ),
    );
  }
}
