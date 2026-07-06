/// main.dart
/// ---------
/// App entry point. Wires SearchViewModel into the widget tree using
/// ChangeNotifierProvider — this is what lets SearchView reach the
/// ViewModel via `context.watch<SearchViewModel>()`.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/search_viewmodel.dart';
import 'views/search_view.dart';

void main() {
  runApp(const GammaAIApp());
}

class GammaAIApp extends StatelessWidget {
  const GammaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // create: builds ONE SearchViewModel instance, shared by any
      // descendant widget that asks for it via context.watch/read.
      create: (_) => SearchViewModel(),
      child: MaterialApp(
        title: 'GammaAI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SearchView(),
      ),
    );
  }
}
