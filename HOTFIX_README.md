# Riverpod und Freezed Fehler behoben

Diese temporäre Lösung ermöglicht die Kompilierung der App ohne die generierten Dateien von Riverpod und Freezed. 

## Vorgenommene Änderungen:

1. TroubleReportState wurde direkt in trouble_report_notifier.dart integriert
2. Manuelle Implementierung von trouble_report_notifier.g.dart wurde erstellt
3. Mock-Klassen für die Services wurden implementiert:
   - MockImageStorageService
   - MockTroubleReportRepository
4. Die problematischen generierten Dateien wurden entfernt

## Sobald die Build-Runner-Fehler behoben sind:

1. Deaktiviere die temporären Implementierungen und entferne die Mock-Klassen
2. Aktiviere die part-Direktiven in TroubleReport und TroubleReportState
3. Setze die @freezed und @riverpod Annotationen wieder ein
4. Führe `flutter pub run build_runner build --delete-conflicting-outputs` aus

## Alternativ für eine langfristige Lösung:

1. Aktualisiere die Abhängigkeiten in pubspec.yaml:
   ```yaml
   dependencies:
     riverpod: ^2.5.0
     riverpod_annotation: ^2.3.3
     freezed_annotation: ^2.4.1
   
   dev_dependencies:
     build_runner: ^2.4.8
     freezed: ^2.4.5
     json_serializable: ^6.7.1
     # Deaktiviere temporär custom_lint
     # custom_lint: ^0.5.7
     # riverpod_lint: ^2.3.7
     riverpod_generator: ^2.3.7
   ```
2. Führe `flutter pub get` aus
3. Versuche erneut den build_runner auszuführen

Die App sollte jetzt ohne Fehler kompilieren und ausführbar sein! 