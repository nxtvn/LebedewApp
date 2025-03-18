# Riverpod-Migration - Temporäre Lösung

## Übersicht

Dieses Projekt befindet sich in einer Übergangsphase von Provider zu Riverpod. Die aktuellen Änderungen stellen eine temporäre Lösung dar, um die App kompilierbar zu machen, während die Migration weiterläuft.

## Gemachte Änderungen

1. **Provider-Dateien manuell implementiert**: Wir haben die Riverpod-Generierung mit @riverpod-Annotationen durch manuelle Provider-Implementierungen ersetzt.
   - Betrifft: `repository_providers.dart`, `service_providers.dart`

2. **TroubleReportNotifier**: Eine temporäre Implementation des TroubleReportNotifiers wurde erstellt, die Mock-Services für ImageStorage und TroubleReportRepository verwendet.

3. **ViewModel-Provider**: Ein Provider für das TroubleReportViewModel wurde hinzugefügt, der mit dem manuellen Repository-Provider arbeitet.

4. **Formular-Komponenten**: Die Android- und iOS-Formularkomponenten wurden aktualisiert, um Riverpod anstelle von Provider zu verwenden.

## Bekannte Probleme

- Die Implementierungen sind teilweise noch unvollständig
- Es können noch Linter-Fehler auftreten, besonders bei den Interface-Implementierungen
- Die Consumer-Widgets in den iOS-Formular-Dateien müssen überarbeitet werden

## Nächste Schritte

1. Aktualisieren Sie die Riverpod-Abhängigkeiten in der pubspec.yaml:
   ```yaml
   flutter_riverpod: ^2.4.9
   riverpod_annotation: ^2.3.3
   ```

2. Führen Sie nach dem Update einen neuen Build aus:
   ```
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Ersetzen Sie die temporären Mock-Implementierungen durch die generierten Dateien

4. Vervollständigen Sie die Migration aller Consumer-Widgets und ViewModel-Implementierungen 