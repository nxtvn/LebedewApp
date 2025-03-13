import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Fassade für die Netzwerkinformationen
/// 
/// Diese Klasse bietet eine einfache Schnittstelle zur Überwachung des Netzwerkstatus
/// und zur Überprüfung der Internetverbindung.
class NetworkInfoFacade {
  static final _log = Logger('NetworkInfoFacade');
  final _connectivity = Connectivity();
  final _connectionChecker = InternetConnectionChecker();
  final _connectionStatusController = StreamController<bool>.broadcast();
  bool _lastKnownStatus = false;
  
  /// Erstellt eine neue Instanz der NetworkInfoFacade
  /// 
  /// Initialisiert die Überwachung des Netzwerkstatus und startet die Überprüfung
  /// der aktuellen Verbindung.
  NetworkInfoFacade() {
    _log.info('Initialisiere NetworkInfoFacade');
    
    // Initialize with current status
    _checkConnection();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _log.info('Konnektivitätsänderung erkannt: $result');
      _checkConnection();
    });
    
    // Periodically check actual internet connectivity
    Timer.periodic(const Duration(minutes: 2), (_) => _checkConnection());
  }
  
  /// Stream, der Änderungen des Netzwerkstatus meldet
  /// 
  /// Gibt true zurück, wenn eine Internetverbindung besteht, sonst false.
  Stream<bool> get isConnected => _connectionStatusController.stream;
  
  /// Überprüft, ob aktuell eine Internetverbindung besteht
  /// 
  /// Diese Methode prüft nicht nur die Netzwerkschnittstelle, sondern
  /// versucht auch, eine tatsächliche Internetverbindung zu verifizieren.
  Future<bool> get isCurrentlyConnected async {
    // First check if we have any connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    
    // Then verify actual internet connectivity
    try {
      final hasInternet = await _connectionChecker.hasConnection;
      return hasInternet;
    } catch (e) {
      _log.warning('Fehler bei der Überprüfung der Internetverbindung', e);
      // Fall back to connectivity result if checker fails
      return true;
    }
  }
  
  /// Überprüft die aktuelle Verbindung und benachrichtigt Abonnenten bei Änderungen
  Future<void> _checkConnection() async {
    try {
      final isConnected = await isCurrentlyConnected;
      
      // Only notify if status changed
      if (isConnected != _lastKnownStatus) {
        _log.info('Netzwerkstatus geändert: ${isConnected ? "Verbunden" : "Nicht verbunden"}');
        _lastKnownStatus = isConnected;
        _connectionStatusController.add(isConnected);
      }
    } catch (e) {
      _log.severe('Fehler bei der Netzwerkstatusüberprüfung', e);
    }
  }
  
  /// Erzwingt eine sofortige Überprüfung der Netzwerkverbindung
  /// 
  /// Nützlich, wenn die App aus dem Hintergrund zurückkehrt oder
  /// wenn der Benutzer eine manuelle Aktualisierung anfordert.
  Future<bool> checkConnectionNow() async {
    await _checkConnection();
    return _lastKnownStatus;
  }
  
  /// Gibt Ressourcen frei
  void dispose() {
    _log.info('Beende NetworkInfoFacade');
    _connectionStatusController.close();
  }
} 