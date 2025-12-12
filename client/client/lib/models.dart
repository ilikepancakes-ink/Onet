class ServerInfo {
  final String name;
  final String version;
  final String country;
  final Map<String, dynamic> otherInfo;

  ServerInfo({
    required this.name,
    required this.version,
    required this.country,
    required this.otherInfo,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      name: json['server_name'] ?? '',
      version: json['version'] ?? '',
      country: json['country'] ?? '',
      otherInfo: json..remove('server_name')..remove('version')..remove('country'),
    );
  }
}

class AuthResponse {
  final String token;

  AuthResponse({required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(token: json['token'] ?? '');
  }
}

class ContentItem {
  final String name;
  final bool isFolder;
  final int? size; // optional

  ContentItem({
    required this.name,
    required this.isFolder,
    this.size,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      name: json['name'] ?? '',
      isFolder: json['is_folder'] ?? false,
      size: json['size'],
    );
  }
}
