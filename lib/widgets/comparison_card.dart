/// comparison_card.dart
/// ---------------------
/// Part of the VIEW layer — pure, stateless widget for the multi-LLM
/// "council" result. Shows the judge's final answer up top, then lets the
/// user expand each individual provider's raw answer for comparison.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comparison_response.dart';
import '../viewmodels/search_viewmodel.dart';

class ComparisonCard extends StatelessWidget {
  final ComparisonResponse result;

  const ComparisonCard({super.key, required this.result});

  IconData _iconFor(String provider) {
    switch (provider) {
      case 'claude':
        return Icons.auto_awesome;
      case 'openai':
        return Icons.chat_bubble_outline;
      case 'gemini':
        return Icons.star_outline;
      case 'grok':
        return Icons.bolt_outlined;
      default:
        return Icons.smart_toy_outlined;
    }
  }

  String _labelFor(String provider) {
    switch (provider) {
      case 'claude':
        return 'Claude (Anthropic)';
      case 'openai':
        return 'ChatGPT (OpenAI)';
      case 'gemini':
        return 'Gemini (Google)';
      case 'grok':
        return 'Grok (xAI)';
      default:
        return provider;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                result.winnerProvider != null
                    ? 'Best answer — ${_labelFor(result.winnerProvider!)}'
                    : 'Best answer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined),
                onPressed: () {
                  context.read<SearchViewModel>().speak(result.finalAnswer);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            result.finalAnswer,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (result.reasoning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Judge\'s reasoning',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              result.reasoning,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Individual model answers',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...result.providerAnswers.map((a) => _ProviderTile(
                icon: _iconFor(a.provider),
                label: _labelFor(a.provider),
                answer: a,
                isWinner: a.provider == result.winnerProvider,
              )),
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final ProviderAnswer answer;
  final bool isWinner;

  const _ProviderTile({
    required this.icon,
    required this.label,
    required this.answer,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isWinner
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
          : null,
      child: ExpansionTile(
        leading: Icon(icon),
        title: Row(
          children: [
            Text(label),
            if (isWinner) ...[
              const SizedBox(width: 6),
              const Icon(Icons.star, size: 16, color: Colors.amber),
            ],
          ],
        ),
        subtitle: Text(
          answer.ok
              ? '${answer.latencyMs} ms'
              : 'Failed: ${answer.error ?? "unknown error"}',
          style: TextStyle(
            color: answer.ok ? null : Theme.of(context).colorScheme.error,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              answer.ok ? answer.answer : (answer.error ?? 'No answer.'),
            ),
          ),
        ],
      ),
    );
  }
}
