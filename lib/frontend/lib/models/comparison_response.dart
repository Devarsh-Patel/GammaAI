/// comparison_response.dart
/// -------------------------
/// MODEL LAYER for the new /compare endpoint (multi-LLM council).
/// Mirrors backend/app/models/comparison_schemas.py — keep both in sync.

class ProviderAnswer {
  final String provider; // "claude" | "openai" | "gemini" | "grok"
  final String model;
  final bool ok;
  final String answer;
  final String? error;
  final int latencyMs;

  ProviderAnswer({
    required this.provider,
    required this.model,
    required this.ok,
    required this.answer,
    required this.error,
    required this.latencyMs,
  });

  factory ProviderAnswer.fromJson(Map<String, dynamic> json) {
    return ProviderAnswer(
      provider: json['provider'] as String,
      model: json['model'] as String,
      ok: json['ok'] as bool,
      answer: json['answer'] as String? ?? '',
      error: json['error'] as String?,
      latencyMs: json['latency_ms'] as int? ?? 0,
    );
  }
}

class ProviderScore {
  final int answerIndex;
  final String provider;
  final double? score;
  final String notes;

  ProviderScore({
    required this.answerIndex,
    required this.provider,
    required this.score,
    required this.notes,
  });

  factory ProviderScore.fromJson(Map<String, dynamic> json) {
    return ProviderScore(
      answerIndex: json['answer_index'] as int,
      provider: json['provider'] as String,
      score: (json['score'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
    );
  }
}

class ComparisonResponse {
  final String query;
  final String mode; // "pick_best" | "synthesize"
  final List<ProviderAnswer> providerAnswers;
  final List<ProviderScore> scores;
  final String? winnerProvider;
  final String finalAnswer;
  final String reasoning;

  ComparisonResponse({
    required this.query,
    required this.mode,
    required this.providerAnswers,
    required this.scores,
    required this.winnerProvider,
    required this.finalAnswer,
    required this.reasoning,
  });

  factory ComparisonResponse.fromJson(Map<String, dynamic> json) {
    return ComparisonResponse(
      query: json['query'] as String,
      mode: json['mode'] as String,
      providerAnswers: (json['provider_answers'] as List)
          .map((e) => ProviderAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
      scores: (json['scores'] as List)
          .map((e) => ProviderScore.fromJson(e as Map<String, dynamic>))
          .toList(),
      winnerProvider: json['winner_provider'] as String?,
      finalAnswer: json['final_answer'] as String,
      reasoning: json['reasoning'] as String,
    );
  }
}
