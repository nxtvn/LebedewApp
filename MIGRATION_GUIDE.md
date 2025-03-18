# Migrationsleitfaden: Provider zu Riverpod, Freezed und Clean Architecture

Dieser Leitfaden dokumentiert die Umstellung der Lebedew-App von Provider auf Riverpod, die Einführung von Freezed für Datenmodelle und die Stärkung der Clean Architecture.

## Allgemeine Änderungen

1. **Abhängigkeiten**: Aktualisierung der pubspec.yaml mit neuen Paketen:
   - Umstellung von Provider auf Flutter Riverpod
   - Hinzufügen von Freezed für unveränderliche Datenmodelle
   - Hinzufügen von JSON-Serialisierung

2. **Code-Generierung**: Einrichtung von Build Runner für:
   - Freezed-Generierung (`*.freezed.dart`)
   - JSON-Serialisierung (`*.g.dart`) 
   - Riverpod-Provider (`*.g.dart`)

3. **Verzeichnisstruktur**: Verbesserte Clean Architecture Struktur:
   - `lib/application/`: Anwendungslogik, Notifier/Controller (früher ViewModels)
   - `lib/domain/`: Domänenmodelle, Schnittstellen, Geschäftsregeln
   - `lib/infrastructure/`: Implementierungen, Provider, externe Dienste
   - `lib/presentation/`: UI-Komponenten, Screens, Widgets

## Spezifische Änderungen

### 1. Datenmodelle mit Freezed

Alle Entitäten wurden auf Freezed umgestellt, z.B. `TroubleReport`:
- Unveränderliche Datenklassen
- Automatisch generierte Methoden (copyWith, ==, toString, etc.)
- JSON-Serialisierung und -Deserialisierung
- Typsichere Enums mit JSON-Unterstützung

### 2. State Management mit Riverpod

Umstellung von `ChangeNotifier`-basierten ViewModels auf Riverpod:
- Zustandstrennung mit `.freezed.dart`-Dateien
- Notifier für Geschäftslogik
- Provider für Abhängigkeiten
- Klare Trennung zwischen Zustand und Verhalten

### 3. Abhängigkeitsinjektion 

- Neue Provider-Struktur in `lib/infrastructure/providers/`
- Hierarchie von Providern für Services, Repositories und Core-Funktionalitäten
- Bessere Testbarkeit durch einfacheres Mocking

## Wie Du die aktualisierten Dateien verwendest

### Zustandsverwaltung

Statt eines ViewModels mit `Provider.of<T>` zu verwenden:

```dart
// ALT (mit Provider)
final viewModel = Provider.of<TroubleReportViewModel>(context);
viewModel.setName("Max Mustermann");

// NEU (mit Riverpod)
ref.read(troubleReportNotifierProvider.notifier).setName("Max Mustermann");
```

### Zustandsbeobachtung

Statt eines Consumers mit Provider:

```dart
// ALT (mit Provider)
Consumer<TroubleReportViewModel>(
  builder: (context, viewModel, _) {
    return Text(viewModel.name);
  }
)

// NEU (mit Riverpod)
Consumer(
  builder: (context, ref, _) {
    final state = ref.watch(troubleReportNotifierProvider);
    return Text(state.report.name);
  }
)
```

## Migration abschließen

Um die Migration abzuschließen, führe folgenden Befehl aus, um die generierten Dateien zu erstellen:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Beachte, dass noch weitere Klassen migriert werden müssen. Dieser Leitfaden und die bisherigen Änderungen dienen als Ausgangspunkt und Vorlage für die weitere Migration.

## Vorteile der neuen Architektur

1. **Bessere Codequalität**: Klare Trennung von Zustand und Verhalten
2. **Erhöhte Testbarkeit**: Einfachere Testbarkeit durch strukturiertere Abhängigkeiten
3. **Typensicherheit**: Stark typisierte Modelle und Zustandsübergänge
4. **Wartbarkeit**: Bessere Organisation des Codes nach Clean Architecture-Prinzipien
5. **Entwicklererfahrung**: Bessere IDE-Unterstützung und hilfreiche Fehlerhinweise 