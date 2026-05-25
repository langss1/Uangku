import 'package:http/http.dart' as http;
import 'ssl_pinning_client.dart';

class NetworkService {
  static http.Client _client = http.Client();

  // Initialize the secure HTTP client on app startup
  static Future<void> init() async {
    _client = await SSLPinningClient.create();
  }

  // Get the initialized SSL pinned client
  static http.Client get client => _client;

  // Centralized HTTP verb wrappers matching standard package signatures
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _client.get(url, headers: headers);
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Object? encoding}) {
    return _client.post(url, headers: headers, body: body, encoding: encoding as dynamic);
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Object? encoding}) {
    return _client.put(url, headers: headers, body: body, encoding: encoding as dynamic);
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Object? encoding}) {
    return _client.delete(url, headers: headers, body: body, encoding: encoding as dynamic);
  }
}
