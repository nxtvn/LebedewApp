import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfoFacade {
  final _connectivity = Connectivity();
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  NetworkInfoFacade() {
    // Initialize with current status
    _checkConnection();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((_) => _checkConnection());
  }
  
  Stream<bool> get isConnected => _connectionStatusController.stream;
  
  Future<bool> get isCurrentlyConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  Future<void> _checkConnection() async {
    final isConnected = await isCurrentlyConnected;
    _connectionStatusController.add(isConnected);
  }
  
  void dispose() {
    _connectionStatusController.close();
  }
} 