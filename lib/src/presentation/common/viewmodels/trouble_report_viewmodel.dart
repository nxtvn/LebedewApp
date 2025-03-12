import 'package:flutter/foundation.dart';
import '../../../domain/entities/trouble_report.dart';
import '../../../domain/repositories/trouble_report_repository.dart';
import '../../../data/datasources/trouble_report_local_data_source.dart';
import '../../../core/network/network_info.dart';

class TroubleReportViewModel extends ChangeNotifier {
  final TroubleReportRepository _troubleReportRepository;
  final TroubleReportLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  TroubleReportViewModel(
    this._troubleReportRepository,
    this._localDataSource,
    this._networkInfo,
  );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> submitReport(TroubleReport troubleReport) async {
    _isLoading = true;
    notifyListeners();

    bool isSuccess = false;

    if (await _networkInfo.isConnected) {
      isSuccess = await _troubleReportRepository.submitReport(troubleReport);
      if (isSuccess) {
        await _localDataSource.updateTroubleReportSyncStatus(troubleReport.id, true);
      }
    } else {
      await _localDataSource.cacheTroubleReport(troubleReport);
    }

    _isLoading = false;
    notifyListeners();

    return isSuccess;
  }

  Future<void> syncCachedReports() async {
    if (await _networkInfo.isConnected) {
      final cachedReports = await _localDataSource.getCachedTroubleReports();
      for (final report in cachedReports) {
        if (!report.isSynced) {
          final isSuccess = await _troubleReportRepository.submitReport(report);
          if (isSuccess) {
            await _localDataSource.updateTroubleReportSyncStatus(report.id, true);
          }
        }
      }
    }
  }

  void reset() async {
    // TODO: Implement reset logic
    await _localDataSource.clearCache();
  }
}