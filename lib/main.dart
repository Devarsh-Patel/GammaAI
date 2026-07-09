/// main.dart
/// ---------
/// App entry point. Wires SearchViewModel into the widget tree using
/// ChangeNotifierProvider — this is what lets SearchView reach the
/// ViewModel via `context.watch<SearchViewModel>()`.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/search_view.dart';
import 'views/signin_view.dart';

void main() {
  runApp(const GammaAIApp());
}

class GammaAIApp extends StatelessWidget {
  const GammaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
      ],
      child: MaterialApp(
        title: 'GammaAI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    
    if (authViewModel.isAuthenticated) {
      return const SearchView();
    } else {
      return const SignInView();
    }
  }
}

