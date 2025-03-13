import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/network/network_info_facade.dart';
import '../../../core/config/injection.dart';

/// Banner, das den Offline-Status anzeigt
/// 
/// Diese Komponente zeigt ein Banner an, wenn keine Internetverbindung besteht.
/// Sie kann in jeder Ansicht verwendet werden, um dem Benutzer Feedback zu geben.
class OfflineStatusBanner extends StatefulWidget {
  final Widget child;
  
  const OfflineStatusBanner({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  late final NetworkInfoFacade _networkInfo;
  bool _isOffline = false;
  StreamSubscription? _networkSubscription;
  
  @override
  void initState() {
    super.initState();
    _networkInfo = getIt<NetworkInfoFacade>();
    
    // Initialen Status prüfen
    _checkConnectionStatus();
    
    // Auf Änderungen des Netzwerkstatus hören
    _networkSubscription = _networkInfo.isConnected.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });
      }
    });
  }
  
  @override
  void dispose() {
    // StreamSubscription abmelden, um Memory Leaks zu vermeiden
    // Dies ist wichtig, um sicherzustellen, dass der Netzwerk-Listener nicht aktiv bleibt,
    // nachdem die Widget-Instanz entfernt wurde
    _networkSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _checkConnectionStatus() async {
    final isConnected = await _networkInfo.isCurrentlyConnected;
    if (mounted) {
      setState(() {
        _isOffline = !isConnected;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          Material(
            elevation: 4,
            child: Container(
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Semantics(
                    label: 'Offline-Symbol',
                    child: const Icon(
                      Icons.wifi_off,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      label: 'Offline-Status-Hinweis',
                      child: const Text(
                        'Sie sind offline. Formulare werden automatisch gesendet, sobald die Verbindung wiederhergestellt ist.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Semantics(
                    label: 'Verbindungsstatus aktualisieren',
                    child: IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await _checkConnectionStatus();
                      },
                      tooltip: 'Verbindung prüfen',
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
} 