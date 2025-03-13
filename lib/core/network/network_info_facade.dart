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
  
  Timer? _periodicCheckTimer;
  Timer? _connectedCheckTimer;
  StreamSubscription? _connectivitySubscription;
  
  /// Erstellt eine neue Instanz der NetworkInfoFacade
  /// 
  /// Initialisiert die Überwachung des Netzwerkstatus und startet die Überprüfung
  /// der aktuellen Verbindung.
  NetworkInfoFacade() {
    _log.info('Initialisiere NetworkInfoFacade');
    
    // Initialize with current status
    _checkConnection();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      _log.info('Konnektivitätsänderung erkannt: $result');
      _checkConnection();
    });
    
    // Periodically check actual internet connectivity
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 2), (_) => _checkConnection());
    
    // Increase check frequency when connected (every 30 seconds instead of 2 minutes)
    _connectedCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_lastKnownStatus) {
        _checkConnection();
      }
    });
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
    try {
      // Check basic connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Enhanced robustness check with timeout
      return await _connectionChecker.hasConnection.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _log.warning('Timeout during connection check');
          return false;
        },
      );
    } catch (e) {
      _log.warning('Error checking internet connection: $e');
      return false;
    }
  }
  
  /// Registriert einen Listener für Änderungen des Verbindungsstatus
  /// 
  /// Der Listener wird sofort mit dem aktuellen Status aufgerufen und dann
  /// jedes Mal, wenn sich der Verbindungsstatus ändert.
  void addConnectionStatusListener(void Function(bool isConnected) listener) {
    _connectionStatusController.stream.listen(listener);
    // Immediately inform about current status
    isCurrentlyConnected.then(listener);
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
    
    // StreamController schließen
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.close();
    }
    
    // Timer abbrechen
    _periodicCheckTimer?.cancel();
    _connectedCheckTimer?.cancel();
    
    // StreamSubscription abmelden
    _connectivitySubscription?.cancel();
  }
} 