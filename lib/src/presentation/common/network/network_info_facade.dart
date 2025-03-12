import '../../../core/network/network_info.dart';

class NetworkInfoFacade {
  final NetworkInfo _networkInfo;

  NetworkInfoFacade(this._networkInfo);

  Stream<bool> get isConnected => _networkInfo.isConnected.asStream();
} 