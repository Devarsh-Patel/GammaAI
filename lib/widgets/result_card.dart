/// result_card.dart
/// -----------------
/// Part of the VIEW layer — a pure, stateless widget. Takes a
/// SearchResponse Model and renders it. Contains no business logic and
/// makes no API calls; it just displays data it's handed.
library;

import 'package:flutter/material.dart';
import '../models/search_response.dart';

class ResultCard extends StatelessWidget {
  final SearchResponse result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Answer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            result.final_.answer,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ExpansionTile(
            title: Text('Researched ${result.plan.subTasks.length} sub-questions'),
            tilePadding: EdgeInsets.zero,
            children: result.plan.subTasks
                .map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• ${t.description}'),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          if (result.final_.sources.isNotEmpty)
            ExpansionTile(
              title: Text('${result.final_.sources.length} sources'),
              tilePadding: EdgeInsets.zero,
              children: result.final_.sources
                  .map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          s,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
