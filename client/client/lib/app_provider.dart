import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'dart:convert';

class AppProvider with ChangeNotifier {
  AppSettings _settings = AppSettings(themeMode: ThemeMode.system, language: 'en');
  List<String> _recentServers = [];
  Map<String, Credentials> _savedCredentials = {};

  AppSettings get settings => _settings;
  List<String> get recentServers => _recentServers;
  Map<String, Credentials> get savedCredentials => _savedCredentials;

  AppProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('settings');
    if (settingsJson != null) {
      _settings = AppSettings.fromJson(jsonDecode(settingsJson));
    }
    final recentServersJson = prefs.getString('recentServers');
    if (recentServersJson != null) {
      _recentServers = List<String>.from(jsonDecode(recentServersJson));
    }
    final credentialsJson = prefs.getString('savedCredentials');
    if (credentialsJson != null) {
      final Map<String, dynamic> credsMap = jsonDecode(credentialsJson);
      _savedCredentials = credsMap.map((key, value) => MapEntry(key, Credentials.fromJson(value)));
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings', jsonEncode(_settings.toJson()));
    await prefs.setString('recentServers', jsonEncode(_recentServers));
    await prefs.setString('savedCredentials', jsonEncode(_savedCredentials.map((key, value) => MapEntry(key, value.toJson()))));
  }

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    _saveData();
    notifyListeners();
  }

  void addRecentServer(String url) {
    _recentServers.remove(url);
    _recentServers.insert(0, url);
    if (_recentServers.length > 5) {
      _recentServers = _recentServers.sublist(0, 5);
    }
    _saveData();
    notifyListeners();
  }

  void saveCredentials(String serverUrl, Credentials creds) {
    _savedCredentials[serverUrl] = creds;
    _saveData();
    notifyListeners();
  }

  void removeCredentials(String serverUrl) {
    _savedCredentials.remove(serverUrl);
    _saveData();
    notifyListeners();
  }

  Credentials? getCredentials(String serverUrl) {
    return _savedCredentials[serverUrl];
  }
}
