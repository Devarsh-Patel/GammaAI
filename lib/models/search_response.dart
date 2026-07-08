/// search_response.dart
/// ---------------------
/// MODEL LAYER (the "M" in MVVM).
///
/// Pure data classes with zero business logic and zero Flutter/UI imports.
/// They only know how to parse themselves from JSON. Mirrors the backend's
/// Pydantic schemas (see backend/app/models/schemas.py) — keep both in sync.
library;

class SubTask {
  final int id;
  final String description;

  SubTask({required this.id, required this.description});

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as int,
      description: json['description'] as String,
    );
  }
}

class PlannerOutput {
  final String originalQuery;
  final List<SubTask> subTasks;

  PlannerOutput({required this.originalQuery, required this.subTasks});

  factory PlannerOutput.fromJson(Map<String, dynamic> json) {
    return PlannerOutput(
      originalQuery: json['original_query'] as String,
      subTasks: (json['sub_tasks'] as List)
          .map((e) => SubTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SearchResultItem {
  final int subTaskId;
  final String subTaskDescription;
  final String rawFindings;
  final List<String> sources;

  SearchResultItem({
    required this.subTaskId,
    required this.subTaskDescription,
    required this.rawFindings,
    required this.sources,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      subTaskId: json['sub_task_id'] as int,
      subTaskDescription: json['sub_task_description'] as String,
      rawFindings: json['raw_findings'] as String,
      sources: (json['sources'] as List).map((e) => e as String).toList(),
    );
  }
}

class SynthesizedAnswer {
  final String answer;
  final List<String> sources;

  SynthesizedAnswer({required this.answer, required this.sources});

  factory SynthesizedAnswer.fromJson(Map<String, dynamic> json) {
    return SynthesizedAnswer(
      answer: json['answer'] as String,
      sources: (json['sources'] as List).map((e) => e as String).toList(),
    );
  }
}

class SearchResponse {
  final String query;
  final PlannerOutput plan;
  final List<SearchResultItem> searchResults;
  final SynthesizedAnswer final_;

  SearchResponse({
    required this.query,
    required this.plan,
    required this.searchResults,
    required this.final_,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query'] as String,
      plan: PlannerOutput.fromJson(json['plan'] as Map<String, dynamic>),
      searchResults: (json['search_results'] as List)
          .map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      final_: SynthesizedAnswer.fromJson(json['final'] as Map<String, dynamic>),
    );
  }
}
