# GammaAI Flutter App — MVVM Architecture

## Folder structure and MVVM mapping

```
lib/
├── models/
│   └── search_response.dart      # MODEL — pure data classes, JSON parsing only
├── services/
│   └── api_service.dart          # Data access — HTTP calls to the backend
├── viewmodels/
│   └── search_viewmodel.dart     # VIEWMODEL — state + logic, ChangeNotifier
├── views/
│   └── search_view.dart          # VIEW — UI that watches the ViewModel
├── widgets/
│   └── result_card.dart          # VIEW (component) — stateless, dumb display
└── main.dart                     # Wires ViewModel into the widget tree via Provider
```

### Why this split matters
- **Model** (`models/`) — knows nothing about Flutter, HTTP, or the ViewModel. Just data + `fromJson()`.
- **Service** (`services/`) — knows how to fetch data over HTTP, returns Models. Knows nothing about UI state.
- **ViewModel** (`viewmodels/`) — the brain. Holds `stage`, `result`, `errorMessage` and the logic to update them. Extends `ChangeNotifier` and calls `notifyListeners()` whenever state changes. Has ZERO Flutter widget imports beyond `foundation.dart` — it doesn't know what a `Scaffold` or `BuildContext` is.
- **View** (`views/`, `widgets/`) — pure UI. Reads state via `context.watch<SearchViewModel>()`, forwards user actions via `context.read<SearchViewModel>().runSearch(...)`. Never calls `ApiService` directly.

This means: you could swap `search_view.dart` for a completely different layout, or swap `ApiService` for a mock in tests, without touching the other layers.

## Setup

### 1. Create the Flutter project shell (one-time)
```bash
flutter create gammaai_app
```
Then copy this bundle's `lib/` and `pubspec.yaml` into it, overwriting the defaults.

### 2. Install dependencies
```bash
cd gammaai_app
flutter pub get
```

### 3. Allow local HTTP during development
Both iOS and Android block plain `http://` by default.

**Android** — `android/app/src/main/AndroidManifest.xml`, add to `<application>`:
```xml
<application android:usesCleartextTraffic="true" ... >
```

**iOS** — `ios/Runner/Info.plist`, add:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```
⚠️ Development only — tighten or remove before shipping to production.

### 4. Point at your backend
In `lib/services/api_service.dart`:
- Android emulator → already `10.0.2.2` ✅
- iOS simulator → already `localhost` ✅
- Physical device → edit `_physicalDeviceIp` to your Mac's LAN IP (`ipconfig getifaddr en0`)

### 5. Run
Backend running first (`uvicorn app.main:app --reload --port 8000`), then:
```bash
flutter run
```

## Testing the ViewModel in isolation

Because `SearchViewModel` accepts an `ApiService` via constructor injection, you can test it without a real network:

```dart
class FakeApiService extends ApiService {
  @override
  Future<SearchResponse> search(String query) async {
    // return a hand-built SearchResponse for testing
  }
}

final vm = SearchViewModel(apiService: FakeApiService());
await vm.runSearch('test query');
expect(vm.stage, SearchStage.done);
```

## Note on the staged loading indicator
The backend returns one full response after the pipeline finishes — it isn't streaming yet. The `SearchViewModel.runSearch()` method simulates stage progression with `Timer`s purely for perceived responsiveness. If the backend adds real streaming later (e.g. SSE), replace that Timer logic with real server-pushed events — the View won't need to change at all, since it only ever reads `viewModel.stage`.
