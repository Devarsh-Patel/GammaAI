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
import 'package:flutter/foundation.dart';
import '../models/search_response.dart';
import '../services/api_service.dart';

/// Represents every possible state the search screen can be in.
/// The View reads this to decide what to render — it never guesses.
enum SearchStage { idle, planning, searching, synthesizing, done, error }

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
  Timer? _stageTimer;

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

    _stageTimer?.cancel();
    _stageTimer = Timer(const Duration(seconds: 2), () {
      if (_stage == SearchStage.planning) {
        _stage = SearchStage.searching;
        notifyListeners();
      }
    });
    Timer(const Duration(seconds: 5), () {
      if (_stage == SearchStage.searching) {
        _stage = SearchStage.synthesizing;
        notifyListeners();
      }
    });

    try {
      final response = await _apiService.search(query);
      _stageTimer?.cancel();
      _result = response;
      _stage = SearchStage.done;
    } on ApiException catch (e) {
      _stageTimer?.cancel();
      _errorMessage = e.message;
      _stage = SearchStage.error;
    } catch (e) {
      _stageTimer?.cancel();
      _errorMessage = 'Something unexpected went wrong: $e';
      _stage = SearchStage.error;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    super.dispose();
  }
}
