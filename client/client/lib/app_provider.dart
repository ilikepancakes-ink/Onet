import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'models.dart';
import 'dart:convert';

class AppProvider with ChangeNotifier {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final LocalAuthentication _localAuth = LocalAuthentication();

  AppSettings _settings = AppSettings(themeMode: ThemeMode.system, language: 'en');
  List<String> _recentServers = [];
  Map<String, bool> _savedCredentialFlags = {};

  AppSettings get settings => _settings;
  List<String> get recentServers => _recentServers;
  Map<String, bool> get savedCredentialFlags => _savedCredentialFlags;

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
    final flagsJson = prefs.getString('savedCredentialFlags');
    if (flagsJson != null) {
      final Map<String, dynamic> flagsMap = jsonDecode(flagsJson);
      _savedCredentialFlags = flagsMap.map((key, value) => MapEntry(key, value as bool));
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings', jsonEncode(_settings.toJson()));
    await prefs.setString('recentServers', jsonEncode(_recentServers));
    await prefs.setString('savedCredentialFlags', jsonEncode(_savedCredentialFlags));
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

  Future<void> saveCredentials(String serverUrl, Credentials creds) async {
    await _secureStorage.write(key: 'creds_$serverUrl', value: jsonEncode(creds.toJson()));
    _savedCredentialFlags[serverUrl] = true;
    _saveData();
    notifyListeners();
  }

  Future<void> removeCredentials(String serverUrl) async {
    await _secureStorage.delete(key: 'creds_$serverUrl');
    _savedCredentialFlags.remove(serverUrl);
    _saveData();
    notifyListeners();
  }

  Future<Credentials?> getCredentials(String serverUrl) async {
    if (!_savedCredentialFlags.containsKey(serverUrl) || !_savedCredentialFlags[serverUrl]!) {
      return null;
    }
    // Authenticate first
    bool authenticated = await _localAuth.authenticate(
      localizedReason: 'Authenticate to access saved credentials',
      options: const AuthenticationOptions(biometricOnly: true, useErrorDialogs: true),
    );
    if (!authenticated) {
      return null;
    }
    final credsJson = await _secureStorage.read(key: 'creds_$serverUrl');
    if (credsJson != null) {
      return Credentials.fromJson(jsonDecode(credsJson));
    }
    return null;
  }
}
