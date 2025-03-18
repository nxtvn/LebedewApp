// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trouble_report_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************


/// Der Provider für den TroubleReportNotifier
///
/// Der Provider erstellt eine Instanz des TroubleReportNotifier mit den
/// notwendigen Services.
///
/// Copyable [TroubleReportNotifier].
@ProviderFor(TroubleReportNotifier)
final troubleReportNotifierProvider =
    StateNotifierProvider<TroubleReportNotifier, TroubleReportState>((ref) {
  // Mock-Services für die Entwicklung
  final imageStorageService = MockImageStorageService();
  final troubleReportRepository = MockTroubleReportRepository();
  
  return TroubleReportNotifier(
    imageStorageService,
    troubleReportRepository,
  );
});

/// Abstrakte Klasse für TroubleReportNotifier, wird normalerweise von
/// Riverpod-Generator generiert.
// ignore: unused_element
abstract class _$TroubleReportNotifier
    extends StateNotifier<TroubleReportState> {
  _$TroubleReportNotifier(
    ImageStorageService imageStorageService,
    TroubleReportRepository repository,
  ) : super(const TroubleReportState());

  /// Die Build-Methode wird normalerweise automatisch generiert
  TroubleReportNotifier build(
    ImageStorageService imageStorageService,
    TroubleReportRepository repository,
  );
}

// Stub für Provider-Referenz
class Ref {
  T read<T>(ProviderListenable<T> provider) {
    // Diese Methode ist nur ein Stub und wird zur Laufzeit durch die reale riverpod-Implementierung ersetzt
    throw UnimplementedError();
  }
  
  T watch<T>(ProviderListenable<T> provider) {
    // Diese Methode ist nur ein Stub und wird zur Laufzeit durch die reale riverpod-Implementierung ersetzt
    throw UnimplementedError();
  }
} 