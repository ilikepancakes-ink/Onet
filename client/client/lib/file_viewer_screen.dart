import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'api_service.dart';

class FileViewerScreen extends StatefulWidget {
  final ApiService api;
  final String filePath;

  FileViewerScreen({required this.api, required this.filePath});

  @override
  _FileViewerScreenState createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  Map<String, dynamic>? fileData;
  bool _isLoading = true;
  String? error;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _loadFileContent();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _loadFileContent() async {
    setState(() => _isLoading = true);
    final data = await widget.api.getFileContent(widget.filePath);
    setState(() {
      fileData = data;
      _isLoading = false;
      if (data == null) {
        error = 'Failed to load file content';
      } else if (data['type'] == 'video' && data['url'] != null) {
        _initializeVideo(data['url']);
      }
    });
  }

  void _initializeVideo(String url) {
    final fullUrl = '${widget.api.baseUrl}$url';
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(fullUrl),
      httpHeaders: {'Authorization': 'Bearer ${widget.api.token}'},
    )..initialize().then((_) {
      setState(() {});
    });
  }

  Widget _buildContent() {
    if (fileData == null) return Container();

    final type = fileData!['type'];
    switch (type) {
      case 'text':
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: SelectableText(
            fileData!['content'] ?? '',
            style: TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        );
      case 'image':
        final url = '${widget.api.baseUrl}${fileData!['url']}';
        return Center(
          child: Image.network(
            url,
            headers: {'Authorization': 'Bearer ${widget.api.token}'},
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(child: Text('Failed to load image'));
            },
          ),
        );
      case 'video':
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      default:
        return Center(child: Text('Unsupported file type'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File: ${widget.filePath.split('/').last}'),
        actions: fileData != null && fileData!['type'] == 'video' && _videoController != null && _videoController!.value.isInitialized
            ? [
                IconButton(
                  icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                    });
                  },
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : _buildContent(),
    );
  }
}
