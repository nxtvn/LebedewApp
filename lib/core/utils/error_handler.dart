import 'dart:io';
import 'dart:async';  // Import für TimeoutException
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Enum für verschiedene Arten von Fehlern in der Anwendung
enum AppErrorType {
  network,
  timeout,
  validation,
  submission,
  authentication,
  permission,
  storage,
  unknown
}

/// Klasse zur Repräsentation eines Anwendungsfehlers
class AppError {
  final AppErrorType type;
  final String message;
  final dynamic exception;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.exception,
    this.stackTrace,
  });

  /// Statische Methode zur Erstellung eines Fehlers basierend auf einer Exception
  static AppError fromException(dynamic exception, [StackTrace? stackTrace]) {
    final Logger logger = Logger('AppError');
    
    // Logger für alle Fehler
    logger.severe('Exception aufgetreten', exception, stackTrace);
    
    if (exception is SocketException) {
      return AppError(
        type: AppErrorType.network,
        message: 'Netzwerkfehler: Bitte überprüfen Sie Ihre Internetverbindung.',
        exception: exception,
        stackTrace: stackTrace,
      );
    } else if (exception is TimeoutException) {
      return AppError(
        type: AppErrorType.timeout,
        message: 'Zeitüberschreitung: Die Anfrage hat zu lange gedauert.',
        exception: exception,
        stackTrace: stackTrace,
      );
    } else if (exception is FormatException) {
      return AppError(
        type: AppErrorType.validation,
        message: 'Formatfehler: Die Daten konnten nicht verarbeitet werden.',
        exception: exception,
        stackTrace: stackTrace,
      );
    } else {
      return AppError(
        type: AppErrorType.unknown,
        message: 'Ein unerwarteter Fehler ist aufgetreten: ${exception.toString()}',
        exception: exception,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Zentrale Klasse für die Fehlerbehandlung in der Anwendung
class AppErrorHandler {
  static final Logger _logger = Logger('AppErrorHandler');
  
  /// Behandelt einen Fehler und zeigt eine entsprechende Fehlermeldung an
  static Future<void> handleError(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) async {
    _logger.warning('Fehler wird behandelt: ${error.type}', error.exception, error.stackTrace);
    
    // Zeige Fehlermeldung je nach Plattform an
    _showErrorMessage(context, error, onRetry);
  }
  
  /// Zeigt eine Fehlermeldung in einem Dialog oder Snackbar an
  static void _showErrorMessage(
    BuildContext context, 
    AppError error,
    VoidCallback? onRetry,
  ) {
    // Snackbar für einfache Fehler anzeigen
    String message = _getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: onRetry != null ? SnackBarAction(
          label: 'Wiederholen',
          textColor: Colors.white,
          onPressed: onRetry,
        ) : null,
      ),
    );
  }
  
  /// Gibt eine benutzerfreundliche Fehlermeldung basierend auf dem Fehlertyp zurück
  static String _getErrorMessage(AppError error) {
    switch (error.type) {
      case AppErrorType.network:
        return 'Netzwerkfehler: Bitte überprüfen Sie Ihre Internetverbindung.';
      case AppErrorType.timeout:
        return 'Zeitüberschreitung: Die Anfrage hat zu lange gedauert.';
      case AppErrorType.validation:
        return 'Validierungsfehler: Bitte überprüfen Sie Ihre Eingaben.';
      case AppErrorType.submission:
        return 'Übermittlungsfehler: Die Daten konnten nicht gesendet werden.';
      case AppErrorType.authentication:
        return 'Authentifizierungsfehler: Bitte melden Sie sich erneut an.';
      case AppErrorType.permission:
        return 'Berechtigungsfehler: Die App benötigt weitere Berechtigungen.';
      case AppErrorType.storage:
        return 'Speicherfehler: Die Daten konnten nicht gespeichert werden.';
      case AppErrorType.unknown:
      return error.message;
    }
  }
  
  /// Gibt ein Widget zur Anzeige eines Fehlers zurück
  static Widget buildErrorWidget(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Ein Fehler ist aufgetreten',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(error),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 