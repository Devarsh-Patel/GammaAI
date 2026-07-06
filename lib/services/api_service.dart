/// api_service.dart
/// -----------------
/// SERVICE LAYER — sits below the ViewModel in MVVM.
///
/// Responsible ONLY for talking to the backend over HTTP and turning raw
/// JSON into Model objects. Contains NO UI state (no loading flags, no
/// error messages meant for display) — that belongs in the ViewModel.
/// This separation means the ViewModel can be unit-tested by mocking
/// ApiService, without needing a real network connection.
library;

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/search_response.dart';

class ApiService {
  /// Edit this to your machine's LAN IP when testing on a PHYSICAL device
  /// (find it with `ipconfig getifaddr en0` on Mac). Neither `localhost`
  /// nor `10.0.2.2` reaches your dev machine from a real phone.
  static const String _physicalDeviceIp = '192.168.1.42'; // <-- EDIT THIS

  static const int _port = 8000;

  /// Resolves the correct base URL for whichever platform/emulator this
  /// build is currently running on.
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Assumes the Android EMULATOR. For a real Android phone, swap in
      // _physicalDeviceIp instead.
      return 'http://10.0.2.2:$_port';
    } else if (Platform.isIOS) {
      // Assumes the iOS SIMULATOR. For a real iPhone, swap in
      // _physicalDeviceIp instead.
      return 'http://localhost:$_port';
    }
    return 'http://localhost:$_port';
  }

  /// Calls POST /search and returns the parsed SearchResponse Model.
  /// Throws ApiException on any failure — the ViewModel decides how to
  /// translate that into UI state (error message, retry button, etc.).
  Future<SearchResponse> search(String query) async {
    final uri = Uri.parse('$baseUrl/search');

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'query': query}),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw ApiException(
        'Could not reach the server. Check that the backend is running '
        'and reachable at $baseUrl. ($e)',
      );
    }

    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        detail = decoded['detail']?.toString() ?? response.body;
      } catch (_) {
        // Body wasn't JSON — fall back to raw text.
      }
      throw ApiException('Server error (${response.statusCode}): $detail');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return SearchResponse.fromJson(decoded);
  }

  /// Simple reachability check, e.g. for an app-startup banner.
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
