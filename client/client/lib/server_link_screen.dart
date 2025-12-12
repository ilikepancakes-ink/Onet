import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'auth_screen.dart';

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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthScreen(api: api, serverInfo: serverInfo),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to server')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Onet File Server')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Server URL'),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _connect,
                    child: Text('Connect'),
                  ),
          ],
        ),
      ),
    );
  }
}
