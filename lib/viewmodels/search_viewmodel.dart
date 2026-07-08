/// search_viewmodel.dart
/// ----------------------
/// VIEWMODEL LAYER — the "VM" in MVVM.
///
/// Sits between the View (search_view.dart) and the Service (api_service.dart).
/// Holds all UI-relevant STATE (current stage, result, error message) and
/// all the LOGIC for driving that state, but knows NOTHING about widgets,
/// BuildContext, or how anything is drawn on screen.
///
/// Extends ChangeNotifier so the View can listen for state changes via
/// the `provider` package and rebuild automatically when notifyListeners()
/// is called. This is the same pattern used in the GodAI app.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/search_response.dart';
import '../models/comparison_response.dart';
import '../services/api_service.dart';

/// Represents every possible state the search screen can be in.
/// The View reads this to decide what to render — it never guesses.
enum SearchStage { idle, planning, searching, synthesizing, done, error }

/// Separate stage enum for the multi-LLM "council" comparison flow, kept
/// independent of SearchStage so the two features can run/fail without
/// interfering with each other.
enum CompareStage { idle, comparing, done, error }

class SearchViewModel extends ChangeNotifier {
  final ApiService _apiService;

  SearchViewModel({ApiService? apiService})
      : _apiService = apiService ?? ApiService();
  // Accepting an optional ApiService via constructor (dependency injection)
  // means tests can pass in a fake/mock ApiService instead of hitting a
  // real network — this is the main payoff of separating VM from Service.

  SearchStage _stage = SearchStage.idle;
  SearchResponse? _result;
  String? _errorMessage;
  final List<Timer> _activeTimers = [];

  // --- Public read-only getters the View binds to ---
  SearchStage get stage => _stage;
  SearchResponse? get result => _result;
  String? get errorMessage => _errorMessage;

  bool get isLoading =>
      _stage == SearchStage.planning ||
      _stage == SearchStage.searching ||
      _stage == SearchStage.synthesizing;

  String get stageLabel {
    switch (_stage) {
      case SearchStage.planning:
        return 'Planning...';
      case SearchStage.searching:
        return 'Searching...';
      case SearchStage.synthesizing:
        return 'Synthesizing...';
      default:
        return '';
    }
  }

  void _clearTimers() {
    for (var t in _activeTimers) {
      t.cancel();
    }
    _activeTimers.clear();
  }

  /// Resets the ViewModel to its initial idle state, clearing all results and errors.
  void reset() {
    _clearTimers();
    _stage = SearchStage.idle;
    _result = null;
    _errorMessage = null;
    _compareStage = CompareStage.idle;
    _comparison = null;
    _compareError = null;
    notifyListeners();
  }

  /// Called by the View when the user submits a query.
  ///
  /// NOTE: the backend currently returns ONE response after the full
  /// pipeline finishes rather than streaming stages. The Timer calls below
  /// SIMULATE stage progression purely for perceived responsiveness. If
  /// the backend adds real streaming (e.g. Server-Sent Events) later,
  /// replace this Timer logic with real events pushed from the server.
  Future<void> runSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    _result = null;
    _errorMessage = null;
    _stage = SearchStage.planning;
    notifyListeners();

    _clearTimers();
    _activeTimers.add(Timer(const Duration(seconds: 2), () {
      if (_stage == SearchStage.planning) {
        _stage = SearchStage.searching;
        notifyListeners();
      }
    }));
    _activeTimers.add(Timer(const Duration(seconds: 5), () {
      if (_stage == SearchStage.searching) {
        _stage = SearchStage.synthesizing;
        notifyListeners();
      }
    }));

    try {
      final response = await _apiService.search(query);
      _clearTimers();
      _result = response;
      _stage = SearchStage.done;
      fetchHistory(); // Update history after search
    } on SocketException {
      _clearTimers();
      _errorMessage = 'Could not connect to the backend. Ensure it is running at ${_apiService.baseUrl}';
      _stage = SearchStage.error;
    } on ApiException catch (e) {
      _clearTimers();
      _errorMessage = e.message;
      _stage = SearchStage.error;
    } catch (e) {
      _clearTimers();
      _errorMessage = 'Something unexpected went wrong: $e';
      _stage = SearchStage.error;
    }

    notifyListeners();
  }

  // --------------------------------------------------------------------
  // Multi-LLM comparison ("council") flow — Claude vs ChatGPT vs Gemini
  // vs Grok, judged and merged by an agentic judge step on the backend.
  // --------------------------------------------------------------------

  CompareStage _compareStage = CompareStage.idle;
  ComparisonResponse? _comparison;
  String? _compareError;
  List<dynamic> _history = [];

  final ImagePicker _picker = ImagePicker();
  final FlutterTts _tts = FlutterTts();
  String? _selectedImageB64;
  File? _selectedImageFile;

  CompareStage get compareStage => _compareStage;
  ComparisonResponse? get comparison => _comparison;
  String? get compareError => _compareError;
  bool get isComparing => _compareStage == CompareStage.comparing;
  File? get selectedImageFile => _selectedImageFile;
  List<dynamic> get history => _history;

  Future<void> fetchHistory() async {
    _history = await _apiService.getHistory();
    notifyListeners();
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _selectedImageFile = File(image.path);
      final bytes = await image.readAsBytes();
      _selectedImageB64 = base64Encode(bytes);
      notifyListeners();
    }
  }

  void clearImage() {
    _selectedImageFile = null;
    _selectedImageB64 = null;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  /// Called by the View when the user asks for the multi-model comparison
  /// instead of (or in addition to) the regular planner/search pipeline.
  Future<void> runComparison(String rawQuery, {String mode = 'synthesize'}) async {
    final query = rawQuery.trim();
    if (query.isEmpty && _selectedImageB64 == null) return;

    _comparison = null;
    _compareError = null;
    _compareStage = CompareStage.comparing;
    notifyListeners();

    try {
      final response = await _apiService.compare(
        query, 
        mode: mode,
        imageB64: _selectedImageB64,
      );
      _comparison = response;
      _compareStage = CompareStage.done;
      fetchHistory(); // Update history after comparison
    } on ApiException catch (e) {
      _compareError = e.message;
      _compareStage = CompareStage.error;
    } catch (e) {
      _compareError = 'Something unexpected went wrong: $e';
      _compareStage = CompareStage.error;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _clearTimers();
    super.dispose();
  }
}
