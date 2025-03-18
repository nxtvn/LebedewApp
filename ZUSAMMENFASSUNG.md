# Riverpod Migration - Zusammenfassung

## Problembeschreibung

Die Anwendung wurde von Provider auf Riverpod umgestellt, aber es gibt Probleme mit der Codegenerierung. Die generierten `.g.dart`-Dateien fehlen oder sind veraltet, was zu vielen Linter-Fehlern führt.

## Implementierte Lösung

Wir haben eine temporäre Lösung erstellt, die es ermöglicht, die App zu kompilieren, während die endgültige Migration durchgeführt wird:

1. **Manuelle Provider statt @riverpod-Annotationen**:
   - `repository_providers.dart` und `service_providers.dart` wurden auf manuelle Provider-Definitionen umgestellt
   - Import von `riverpod_annotation` wurde durch `flutter_riverpod` ersetzt
   - `ref.watch` wurde durch `ref.read` ersetzt, wo nötig

2. **Provisorische Implementierung für TroubleReportNotifier**:
   - Temporäre Mock-Klassen für `ImageStorageService` und `TroubleReportRepository`
   - Vereinfachte `TroubleReportState`-Klasse
   - Manuelle Version von `trouble_report_notifier.g.dart` 

3. **Aktualisierung der Benutzeroberfläche**:
   - `TroubleReportFormAndroid` und `TroubleReportFormIOS` wurden auf `ConsumerStatefulWidget` umgestellt
   - Formularzustände verwenden jetzt Riverpod statt Provider

4. **Provider für ViewModels**:
   - Hinzufügung eines `troubleReportViewModelProvider` zur einfachen Integration in die UI

## Verbleibende Probleme

Es gibt noch einige Linter-Fehler, die behoben werden müssen:

1. Interface-Implementierungen für die Mock-Klassen sind nicht vollständig
2. `Consumer`-Widgets in iOS-Formularen verwenden möglicherweise falsche Typen
3. Methoden-Signaturen zwischen Mock-Implementierungen und Interfaces passen nicht immer zusammen

## Nächste Schritte

1. Aktualisierung der Riverpod-Abhängigkeiten in `pubspec.yaml` auf die neuesten Versionen
2. Ausführen von `flutter pub run build_runner build --delete-conflicting-outputs`
3. Ersetzen der temporären Implementierungen durch die richtig generierten Dateien
4. Vervollständigen der UI-Migration auf Riverpod 