import 'package:flutter/material.dart';
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
  
  @override
  void initState() {
    super.initState();
    _networkInfo = getIt<NetworkInfoFacade>();
    
    // Initialen Status prüfen
    _checkConnectionStatus();
    
    // Auf Änderungen des Netzwerkstatus hören
    _networkInfo.isConnected.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });
      }
    });
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
                  const Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sie sind offline. Einige Funktionen sind möglicherweise nicht verfügbar.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      await _checkConnectionStatus();
                    },
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