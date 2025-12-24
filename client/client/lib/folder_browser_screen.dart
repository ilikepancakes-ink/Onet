import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
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
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  void _loadContent() async {
    setState(() => _isLoading = true);
    final content = await widget.api.getContent(path: currentPath);
    setState(() {
      items = content ?? [];
      errorMessage = content == null ? 'Failed to load content' : null;
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

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = result.files.first;
      final data = file.bytes!;
      final filename = file.name;
      const chunkSize = 1024 * 1024; // 1MB chunks
      final totalChunks = (data.length / chunkSize).ceil();

      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (i + 1) * chunkSize;
        final chunk = data.sublist(start, end > data.length ? data.length : end);
        final success = await widget.api.uploadFile(currentPath, filename, chunk, i, totalChunks);
        if (!success && i == totalChunks - 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed')),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File uploaded successfully')),
      );
      _loadContent();
    }
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final scale = isMobile ? 1.5 : 1.0;
    return Scaffold(
      appBar: AppBar(
        title: Text('Files: ${currentPath.isEmpty ? '/' : currentPath}', style: TextStyle(fontSize: 20 * scale)),
        leading: currentPath.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                iconSize: 24 * scale,
                onPressed: _goBack,
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file),
            iconSize: 24 * scale,
            onPressed: _uploadFile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: TextStyle(fontSize: 16 * scale)))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SizedBox(
                      height: 60 * scale,
                      child: ListTile(
                        leading: Icon(item.isFolder ? Icons.folder : Icons.insert_drive_file, size: 24 * scale),
                        title: Text(item.name, style: TextStyle(fontSize: 16 * scale)),
                        subtitle: item.size != null ? Text('${item.size} bytes', style: TextStyle(fontSize: 14 * scale)) : null,
                        onTap: item.isFolder ? () => _navigateToFolder(item.name) : () => _openFile(item.name),
                      ),
                    );
                  },
                ),
    );
  }
}
