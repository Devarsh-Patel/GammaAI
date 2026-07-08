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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/search_response.dart';
import '../models/comparison_response.dart';

class ApiService {
  static const int _port = 8000;

  /// Resolves the correct base URL for whichever platform/emulator this
  /// build is currently running on.
  static String get baseUrl {
    if (kIsWeb) {
      // For web, we usually hit the same host or a specific API domain.
      // During local dev, 'localhost' works if the backend is on the same machine.
      return 'http://localhost:$_port';
    }
    if (Platform.isAndroid) {
      // Assumes the Android EMULATOR.
      return 'http://10.0.2.2:$_port';
    }
    // iOS Simulator or macOS Desktop
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

  /// Calls POST /compare — fans a query out to Claude, ChatGPT, Gemini,
  /// and Grok in parallel on the backend, then has a judge model pick or
  /// synthesize the best answer. `mode` is either "pick_best" or
  /// "synthesize" (defaults to synthesize, which tends to produce the
  /// richest answer since it merges the strongest points of each model).
  Future<ComparisonResponse> compare(
    String query, {
    String mode = 'synthesize',
    String? imageB64,
  }) async {
    final uri = Uri.parse('$baseUrl/compare');

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query,
              'mode': mode,
              if (imageB64 != null) 'image_b64': imageB64,
            }),
          )
          .timeout(const Duration(seconds: 90));
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
    return ComparisonResponse.fromJson(decoded);
  }

  /// Sends an audio file to the backend for transcription.
  Future<String> transcribe(String filePath) async {
    final uri = Uri.parse('$baseUrl/transcribe');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw ApiException('Transcription failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['text'] as String;
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

  /// Fetches history items from the backend.
  Future<List<dynamic>> getHistory() async {
    final uri = Uri.parse('$baseUrl/history');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['history'] as List<dynamic>;
      }
    } catch (e) {
      print('Failed to fetch history: $e');
    }
    return [];
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
