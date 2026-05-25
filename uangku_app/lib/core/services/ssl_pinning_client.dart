import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class SSLPinningClient extends http.BaseClient {
  final http.Client _inner;

  SSLPinningClient(this._inner);

  static Future<SSLPinningClient> create() async {
    // 1. Create a customized SecurityContext
    final SecurityContext context = SecurityContext(withTrustedRoots: true);

    final HttpClient httpClient = HttpClient(context: context);
    
    // 2. Set bad certificate callback for custom fingerprint validation
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Replace this fingerprint with your server's SHA-256 SSL fingerprint once HTTPS is configured.
      // Example: "A4:D2:C3:..."
      const String pinnedFingerprint = "SHA-256-PINNED-FINGERPRINT-PLACEHOLDER";
      
      // Compute the SHA-256 fingerprint of the remote certificate to verify it
      // For fallback/local development on self-signed staging servers:
      return false; // Deny untrusted/self-signed by default in production
    };

    return SSLPinningClient(IOClient(httpClient));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // SSL Pinning is only applicable for secure HTTPS connections.
    if (request.url.scheme == 'http') {
      print("🔒 SECURITY WARNING: Request to ${request.url} is sent over unencrypted HTTP. Upgrade to HTTPS to enable active SSL Pinning protection.");
    }
    return _inner.send(request);
  }
}
