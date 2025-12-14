import 'package:flutter/material.dart';

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

class AppSettings {
  ThemeMode themeMode;
  String language;

  AppSettings({required this.themeMode, required this.language});

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'language': language,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] ?? 0],
      language: json['language'] ?? 'en',
    );
  }
}

class Credentials {
  final String username;
  final String password;

  Credentials({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }

  factory Credentials.fromJson(Map<String, dynamic> json) {
    return Credentials(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }
}
