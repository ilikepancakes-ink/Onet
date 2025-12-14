import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'models.dart';
import 'folder_browser_screen.dart';
import 'app_provider.dart';
import 'l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  final ApiService api;
  final ServerInfo serverInfo;

  AuthScreen({required this.api, required this.serverInfo});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _rememberCredentials = false;

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final creds = appProvider.getCredentials(widget.api.baseUrl);
    if (creds != null) {
      _userController.text = creds.username;
      _passController.text = creds.password;
      _rememberCredentials = true;
    }
  }

  void _login() async {
    final user = _userController.text.trim();
    final pass = _passController.text.trim();
    if (user.isEmpty || pass.isEmpty) return;

    setState(() => _isLoading = true);
    final token = await widget.api.authenticate(user, pass);
    setState(() => _isLoading = false);

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (token != null) {
      if (_rememberCredentials) {
        appProvider.saveCredentials(widget.api.baseUrl, Credentials(username: user, password: pass));
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FolderBrowserScreen(api: widget.api),
        ),
      );
    } else {
      appProvider.removeCredentials(widget.api.baseUrl);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authenticationFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authentication)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Centered prompt
            Center(
              child: Column(
                children: [
                  Text('${l10n.server}: ${widget.serverInfo.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${l10n.version}: ${widget.serverInfo.version}'),
                  Text('${l10n.country}: ${widget.serverInfo.country}'),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _userController,
              decoration: InputDecoration(labelText: l10n.username),
            ),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.password),
            ),
            CheckboxListTile(
              title: Text(l10n.rememberCredentials),
              value: _rememberCredentials,
              onChanged: (value) {
                setState(() => _rememberCredentials = value ?? false);
              },
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text(l10n.login),
                  ),
          ],
        ),
      ),
    );
  }
}
