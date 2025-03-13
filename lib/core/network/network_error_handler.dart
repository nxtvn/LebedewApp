import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'network_info_facade.dart';

/// Fehlertypen für Netzwerkoperationen
enum NetworkErrorType {
  /// Keine Internetverbindung
  noConnection,
  
  /// Timeout bei der Anfrage
  timeout,
  
  /// Server nicht erreichbar
  serverUnreachable,
  
  /// Authentifizierungsfehler
  authentication,
  
  /// Serverfehler
  serverError,
  
  /// Unbekannter Fehler
  unknown
}

/// Handler für Netzwerkfehler
/// 
/// Diese Klasse bietet Methoden zur Behandlung von Netzwerkfehlern und
/// zur Anzeige von benutzerfreundlichen Fehlermeldungen.
class NetworkErrorHandler {
  static final _log = Logger('NetworkErrorHandler');
  final NetworkInfoFacade _networkInfo;
  
  NetworkErrorHandler(this._networkInfo);
  
  /// Bestimmt den Typ eines Netzwerkfehlers
  /// 
  /// Analysiert die Ausnahme und gibt den entsprechenden Fehlertyp zurück.
  NetworkErrorType getErrorType(dynamic error) {
    _log.warning('Netzwerkfehler aufgetreten', error);
    
    if (error is SocketException) {
      return NetworkErrorType.serverUnreachable;
    } else if (error is TimeoutException) {
      return NetworkErrorType.timeout;
    } else if (error is HttpException) {
      if (error.message.contains('401') || error.message.contains('403')) {
        return NetworkErrorType.authentication;
      } else if (error.message.contains('5')) {
        return NetworkErrorType.serverError;
      }
    }
    
    return NetworkErrorType.unknown;
  }
  
  /// Gibt eine benutzerfreundliche Fehlermeldung zurück
  /// 
  /// Basierend auf dem Fehlertyp wird eine passende Meldung zurückgegeben.
  String getErrorMessage(NetworkErrorType errorType) {
    switch (errorType) {
      case NetworkErrorType.noConnection:
        return 'Keine Internetverbindung. Bitte überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.';
      case NetworkErrorType.timeout:
        return 'Die Anfrage hat zu lange gedauert. Bitte versuchen Sie es später erneut.';
      case NetworkErrorType.serverUnreachable:
        return 'Der Server ist nicht erreichbar. Bitte versuchen Sie es später erneut.';
      case NetworkErrorType.authentication:
        return 'Authentifizierungsfehler. Bitte melden Sie sich erneut an.';
      case NetworkErrorType.serverError:
        return 'Ein Serverfehler ist aufgetreten. Bitte versuchen Sie es später erneut.';
      case NetworkErrorType.unknown:
        return 'Ein unbekannter Fehler ist aufgetreten. Bitte versuchen Sie es später erneut.';
    }
  }
  
  /// Zeigt eine Fehlermeldung an
  /// 
  /// Zeigt eine Snackbar mit einer benutzerfreundlichen Fehlermeldung an.
  void showErrorSnackbar(BuildContext context, dynamic error) async {
    // Prüfe zuerst, ob eine Internetverbindung besteht
    final isConnected = await _networkInfo.isCurrentlyConnected;
    
    // Prüfe, ob der BuildContext noch gültig ist
    if (!context.mounted) return;
    
    final errorType = isConnected ? getErrorType(error) : NetworkErrorType.noConnection;
    final errorMessage = getErrorMessage(errorType);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  /// Führt eine Netzwerkoperation mit Fehlerbehandlung aus
  /// 
  /// Führt die übergebene Funktion aus und behandelt auftretende Fehler.
  /// 
  /// Parameter:
  /// - context: Der BuildContext für die Anzeige von Fehlermeldungen
  /// - operation: Die auszuführende Netzwerkoperation
  /// - onSuccess: Callback für erfolgreiche Ausführung
  /// - onError: Optionaler Callback für Fehler
  /// - showError: Ob Fehler angezeigt werden sollen (Standard: true)
  Future<void> executeWithErrorHandling<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    required Function(T result) onSuccess,
    Function(dynamic error)? onError,
    bool showError = true,
  }) async {
    try {
      // Prüfe zuerst, ob eine Internetverbindung besteht
      final isConnected = await _networkInfo.isCurrentlyConnected;
      
      // Prüfe, ob der BuildContext noch gültig ist
      if (!context.mounted) return;
      
      if (!isConnected) {
        if (showError) {
          showErrorSnackbar(context, null);
        }
        
        if (onError != null) {
          onError(Exception('No internet connection'));
        }
        
        return;
      }
      
      // Führe die Operation aus
      final result = await operation();
      
      // Prüfe, ob der BuildContext noch gültig ist
      if (!context.mounted) return;
      
      onSuccess(result);
    } catch (e) {
      _log.warning('Fehler bei Netzwerkoperation', e);
      
      // Prüfe, ob der BuildContext noch gültig ist
      if (!context.mounted) return;
      
      if (showError) {
        showErrorSnackbar(context, e);
      }
      
      if (onError != null) {
        onError(e);
      }
    }
  }
} 