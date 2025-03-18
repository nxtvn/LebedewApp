import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/network_info_facade.dart';

/// Provider für den Network-Info-Service
/// 
/// Dieser Service ist zuständig für die Überprüfung der Netzwerkverbindung.
final networkInfoProvider = Provider<NetworkInfoFacade>((ref) {
  return NetworkInfoFacade();
}); 