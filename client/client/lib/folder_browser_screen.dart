import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'file_viewer_screen.dart';

class FolderBrowserScreen extends StatefulWidget {
  final ApiService api;

  const FolderBrowserScreen({super.key, required this.api});

  @override
  _FolderBrowserScreenState createState() => _FolderBrowserScreenState();
}

class _FolderBrowserScreenState extends State<FolderBrowserScreen> {
  String currentPath = '';
  List<ContentItem> items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  void _loadContent() async {
    setState(() => _isLoading = true);
    final content = await widget.api.getContent(path: currentPath);
    setState(() {
      items = content;
      _isLoading = false;
    });
  }

  void _navigateToFolder(String folderName) {
    setState(() {
      currentPath = currentPath.isEmpty ? folderName : '$currentPath/$folderName';
    });
    _loadContent();
  }

  void _goBack() {
    if (currentPath.isEmpty) return;
    final parts = currentPath.split('/');
    parts.removeLast();
    setState(() {
      currentPath = parts.join('/');
    });
    _loadContent();
  }

  void _openFile(String fileName) {
    final filePath = currentPath.isEmpty ? fileName : '$currentPath/$fileName';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileViewerScreen(api: widget.api, filePath: filePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Files: ${currentPath.isEmpty ? '/' : currentPath}'),
        leading: currentPath.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(item.isFolder ? Icons.folder : Icons.insert_drive_file),
                  title: Text(item.name),
                  subtitle: item.size != null ? Text('${item.size} bytes') : null,
                  onTap: item.isFolder ? () => _navigateToFolder(item.name) : () => _openFile(item.name),
                );
              },
            ),
    );
  }
}
