import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'folder_browser_screen.dart';

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

  void _login() async {
    final user = _userController.text.trim();
    final pass = _passController.text.trim();
    if (user.isEmpty || pass.isEmpty) return;

    setState(() => _isLoading = true);
    final token = await widget.api.authenticate(user, pass);
    setState(() => _isLoading = false);

    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FolderBrowserScreen(api: widget.api),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server: ${widget.serverInfo.name}'),
            Text('Version: ${widget.serverInfo.version}'),
            Text('Country: ${widget.serverInfo.country}'),
            SizedBox(height: 20),
            TextField(
              controller: _userController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
