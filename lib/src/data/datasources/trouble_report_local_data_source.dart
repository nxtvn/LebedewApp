import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/trouble_report.dart';

abstract class TroubleReportLocalDataSource {
  Future<void> cacheTroubleReport(TroubleReport troubleReport);
  Future<List<TroubleReport>> getCachedTroubleReports();
  Future<void> updateTroubleReportSyncStatus(String id, bool isSynced);
  Future<void> clearCache();
}

class TroubleReportLocalDataSourceImpl implements TroubleReportLocalDataSource {
  final SharedPreferences _sharedPreferences;

  TroubleReportLocalDataSourceImpl(this._sharedPreferences);

  static const String _cachedTroubleReportsKey = 'CACHED_TROUBLE_REPORTS';

  @override
  Future<void> cacheTroubleReport(TroubleReport troubleReport) async {
    final cachedReports = await getCachedTroubleReports();
    cachedReports.add(troubleReport);
    await _saveTroubleReportsToCache(cachedReports);
  }

  @override
  Future<List<TroubleReport>> getCachedTroubleReports() async {
    final jsonString = _sharedPreferences.getString(_cachedTroubleReportsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => TroubleReport.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  @override
  Future<void> updateTroubleReportSyncStatus(String id, bool isSynced) async {
    final cachedReports = await getCachedTroubleReports();
    final index = cachedReports.indexWhere((report) => report.id == id);
    if (index != -1) {
      cachedReports[index] = cachedReports[index].copyWith(isSynced: isSynced);
      await _saveTroubleReportsToCache(cachedReports);
    }
  }

  Future<void> _saveTroubleReportsToCache(List<TroubleReport> troubleReports) async {
    final jsonString = json.encode(troubleReports.map((report) => report.toJson()).toList());
    await _sharedPreferences.setString(_cachedTroubleReportsKey, jsonString);
  }

  @override
  Future<void> clearCache() async {
    await _sharedPreferences.clear();
  }
}