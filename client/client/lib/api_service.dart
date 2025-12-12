import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  final String baseUrl;
  String? token;

  ApiService(this.baseUrl);

  Future<ServerInfo?> checkServer() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/init/check'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ServerInfo.fromJson(json);
      }
    } catch (e) {
      print('Error checking server: $e');
    }
    return null;
  }

  Future<String?> authenticate(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/init/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final auth = AuthResponse.fromJson(json);
        token = auth.token;
        return token;
      }
    } catch (e) {
      print('Error authenticating: $e');
    }
    return null;
  }

  Future<List<ContentItem>> getContent({String path = ''}) async {
    try {
      final uri = Uri.parse('$baseUrl/main/content').replace(queryParameters: path.isNotEmpty ? {'path': path} : null);
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json.map((item) => ContentItem.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error getting content: $e');
    }
    return [];
  }
}
