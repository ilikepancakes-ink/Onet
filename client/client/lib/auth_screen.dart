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

  const AuthScreen({super.key, required this.api, required this.serverInfo});

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
        await appProvider.saveCredentials(widget.api.baseUrl, Credentials(username: user, password: pass));
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FolderBrowserScreen(api: widget.api),
        ),
      );
    } else {
      await appProvider.removeCredentials(widget.api.baseUrl);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authenticationFailed)),
      );
    }
  }

  void _loginWithSaved() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final creds = await appProvider.getCredentials(widget.api.baseUrl);
    if (creds != null) {
      setState(() => _isLoading = true);
      final token = await widget.api.authenticate(creds.username, creds.password);
      setState(() => _isLoading = false);
      if (token != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FolderBrowserScreen(api: widget.api),
          ),
        );
      } else {
        await appProvider.removeCredentials(widget.api.baseUrl);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authenticationFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final scale = isMobile ? 1.5 : 1.0;
    final appProvider = Provider.of<AppProvider>(context);
    final hasSaved = appProvider.savedCredentialFlags[widget.api.baseUrl] ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authentication, style: TextStyle(fontSize: 20 * scale))),
      body: Padding(
        padding: EdgeInsets.all(16.0 * scale),
        child: Column(
          children: [
            // Centered prompt
            Center(
              child: Column(
                children: [
                  Text('${l10n.server}: ${widget.serverInfo.name}', style: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.bold)),
                  Text('${l10n.version}: ${widget.serverInfo.version}', style: TextStyle(fontSize: 14 * scale)),
                  Text('${l10n.country}: ${widget.serverInfo.country}', style: TextStyle(fontSize: 14 * scale)),
                ],
              ),
            ),
            SizedBox(height: 20 * scale),
            if (hasSaved)
              ElevatedButton(
                onPressed: _loginWithSaved,
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48 * scale)),
                child: Text('Login with saved credentials', style: TextStyle(fontSize: 16 * scale)),
              ),
            if (hasSaved) SizedBox(height: 10 * scale),
            TextField(
              controller: _userController,
              decoration: InputDecoration(labelText: l10n.username, labelStyle: TextStyle(fontSize: 16 * scale)),
              style: TextStyle(fontSize: 16 * scale),
              contextMenuBuilder: null,
            ),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.password, labelStyle: TextStyle(fontSize: 16 * scale)),
              style: TextStyle(fontSize: 16 * scale),
              contextMenuBuilder: null,
            ),
            CheckboxListTile(
              title: Text(l10n.rememberCredentials, style: TextStyle(fontSize: 14 * scale)),
              value: _rememberCredentials,
              onChanged: (value) {
                setState(() => _rememberCredentials = value ?? false);
              },
            ),
            SizedBox(height: 20 * scale),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48 * scale)),
                    child: Text(l10n.login, style: TextStyle(fontSize: 16 * scale)),
                  ),
          ],
        ),
      ),
    );
  }
}
