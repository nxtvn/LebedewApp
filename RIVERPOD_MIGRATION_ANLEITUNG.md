# Anleitung zur Fehlerbehebung in trouble_report_form_ios.dart

## Problem

In der Datei `lib/presentation/ios/trouble_report_form_ios.dart` gibt es mehrere Linter-Fehler, die durch die Migration von Provider zu Riverpod entstanden sind:

1. Falsche Verwendung von `Consumer<T>` statt nur `Consumer`
2. Fehlerhafte Zugriffe auf ViewModel-Eigenschaften innerhalb des Consumer-Builders
3. Ungenutzte Importe

## Lösung

### 1. Ungenutzte Importe entfernen

Folgende Importe können entfernt werden:

```dart
import '../../core/platform/platform_helper.dart';
import '../../core/constants/design_constants.dart';
import '../../application/trouble_report/trouble_report_notifier.dart';
import 'package:uuid/uuid.dart';
```

### 2. Consumer-Widgets korrekt verwenden

Bei Riverpod wird `Consumer` ohne Typparameter verwendet. Ändern Sie:

```dart
Consumer<TroubleReportViewModel>(
  builder: (context, viewModel, _) {
    // Zugriff auf viewModel-Eigenschaften
  }
)
```

zu:

```dart
Consumer(
  builder: (context, ref, _) {
    final viewModel = ref.watch(troubleReportViewModelProvider);
    // Zugriff auf viewModel-Eigenschaften
  }
)
```

### 3. _buildImagePreview-Methode anpassen

Die Methode `_buildImagePreview` muss die korrekte Signatur für `NullableIndexedWidgetBuilder` haben:

```dart
Widget? _buildImagePreview(BuildContext context, int index) {
  final viewModel = ref.read(troubleReportViewModelProvider);
  // Rest der Methode...
}
```

Und bei der Verwendung in ListView.builder:

```dart
itemBuilder: (context, index) => _buildImagePreview(context, index) ?? Container(),
```

### 4. Methoden-Refactoring

In allen Methoden, die auf _viewModel zugreifen, sollte die State-Verwaltung über ref.watch oder ref.read erfolgen:

- Für Lese-Operationen: `final viewModel = ref.watch(troubleReportViewModelProvider);`
- Für Schreib-Operationen: `ref.read(troubleReportViewModelProvider).methodName(...)`

### 5. Wichtige Stellen, die aktualisiert werden müssen

1. `_updateControllersFromViewModel()`
2. `initState()`
3. `reset()`
4. `_pickImage()`
5. `_buildMaintenanceContractRow()`
6. `_buildUrgencyLevelPicker()`
7. `_getUrgencyColor()`
8. `_buildTermsAcceptanceRow()`

### Beispiele für Korrekturen

#### Consumer-Widget:
```dart
Consumer(
  builder: (context, ref, _) {
    final viewModel = ref.watch(troubleReportViewModelProvider);
    if (!viewModel.hasMaintenanceContract) {
      return const SizedBox.shrink();
    }
    return CupertinoFormRow(
      // ... Rest des Codes
    );
  },
),
```

#### Methode mit State-Zugriff:
```dart
Widget _buildMaintenanceContractRow(BuildContext context) {
  final viewModel = ref.watch(troubleReportViewModelProvider);
  return CupertinoFormRow(
    prefix: const Text('Wartungsvertrag vorhanden'),
    child: CupertinoSwitch(
      value: viewModel.hasMaintenanceContract,
      onChanged: (value) => ref.read(troubleReportViewModelProvider).setHasMaintenanceContract(value),
    ),
  );
}
```

Nach diesen Änderungen sollten alle Linter-Fehler behoben sein. 