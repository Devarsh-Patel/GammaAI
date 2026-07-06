/// search_view.dart
/// -----------------
/// VIEW LAYER — the "V" in MVVM.
///
/// Pure UI: reads state from SearchViewModel (via `provider`'s `watch`/
/// `context.read`) and renders it. Contains NO business logic and makes
/// NO direct API calls — every user action is forwarded to the ViewModel,
/// and every piece of displayed data comes FROM the ViewModel.
///
/// This separation is what makes MVVM useful: you could swap this entire
/// file for a different UI layout without touching SearchViewModel or
/// ApiService at all.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/search_viewmodel.dart';
import '../widgets/result_card.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `watch` subscribes this widget to rebuild whenever the ViewModel
    // calls notifyListeners(). This is the View reacting to VM state.
    final viewModel = context.watch<SearchViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('GammaAI Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                      border: OutlineInputBorder(),
                    ),
                    // context.read (not watch) here: we're just CALLING a
                    // method, not subscribing this callback to rebuilds.
                    onSubmitted: (_) =>
                        context.read<SearchViewModel>().runSearch(_controller.text),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => context
                          .read<SearchViewModel>()
                          .runSearch(_controller.text),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildBody(viewModel)),
          ],
        ),
      ),
    );
  }

  /// Purely reads ViewModel state to decide what to render — no logic
  /// beyond a switch on `stage` lives here.
  Widget _buildBody(SearchViewModel viewModel) {
    if (viewModel.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(viewModel.stageLabel, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    if (viewModel.stage == SearchStage.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            viewModel.errorMessage ?? 'Unknown error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (viewModel.stage == SearchStage.done && viewModel.result != null) {
      return ResultCard(result: viewModel.result!);
    }

    return Center(
      child: Text(
        'Ask a question to get started.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
