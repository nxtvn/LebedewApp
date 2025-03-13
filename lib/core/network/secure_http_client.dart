import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Ein sicherer HTTP-Client mit Timeout, Zertifikatsvalidierung und HTTPS-Unterstützung
///
/// Diese Klasse bietet eine sichere Implementierung eines HTTP-Clients
/// mit Timeout, Zertifikatsüberprüfung und HTTPS-Unterstützung.
class SecureHttpClient {
  static final _log = Logger('SecureHttpClient');
  
  // Timeout-Einstellungen
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 30);
  
  // HTTP-Client mit Timeout
  final http.Client _client = http.Client();
  
  /// Führt eine GET-Anfrage aus
  ///
  /// [url] ist die URL, an die die Anfrage gesendet wird
  /// [headers] sind die HTTP-Header, die mit der Anfrage gesendet werden
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final secureUrl = _ensureHttps(url);
    _log.info('GET-Anfrage an $secureUrl');
    
    try {
      final response = await _client.get(
        Uri.parse(secureUrl),
        headers: headers,
      ).timeout(_connectTimeout);
      
      _validateResponse(response);
      return response;
    } catch (e) {
      _handleError(e, 'GET', secureUrl);
      rethrow;
    }
  }
  
  /// Führt eine POST-Anfrage aus
  ///
  /// [url] ist die URL, an die die Anfrage gesendet wird
  /// [headers] sind die HTTP-Header, die mit der Anfrage gesendet werden
  /// [body] ist der Anfragekörper
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final secureUrl = _ensureHttps(url);
    _log.info('POST-Anfrage an $secureUrl');
    
    try {
      final response = await _client.post(
        Uri.parse(secureUrl),
        headers: headers,
        body: body,
      ).timeout(_receiveTimeout);
      
      _validateResponse(response);
      return response;
    } catch (e) {
      _handleError(e, 'POST', secureUrl);
      rethrow;
    }
  }
  
  /// Stellt sicher, dass die URL HTTPS verwendet
  ///
  /// [url] ist die zu überprüfende URL
  String _ensureHttps(String url) {
    if (url.startsWith('http://')) {
      final secureUrl = url.replaceFirst('http://', 'https://');
      _log.warning('HTTP-URL zu HTTPS konvertiert: $url -> $secureUrl');
      return secureUrl;
    }
    return url;
  }
  
  /// Validiert die HTTP-Antwort
  ///
  /// [response] ist die zu validierende HTTP-Antwort
  void _validateResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _log.warning('HTTP-Fehler: ${response.statusCode} - ${response.reasonPhrase}');
      _log.warning('Antwort: ${response.body}');
      throw HttpException(
        'HTTP-Fehler: ${response.statusCode} - ${response.reasonPhrase}',
        uri: Uri.parse(response.request?.url.toString() ?? ''),
      );
    }
    
    // Validiere den Antwortinhalt, wenn es sich um JSON handelt
    final contentType = response.headers['content-type'];
    if (contentType != null && contentType.contains('application/json')) {
      try {
        final json = jsonDecode(response.body);
        if (json == null) {
          _log.warning('Ungültige JSON-Antwort: null');
          throw const FormatException('Ungültige JSON-Antwort: null');
        }
      } catch (e) {
        _log.warning('Fehler beim Parsen der JSON-Antwort: $e');
        throw FormatException('Ungültige JSON-Antwort: ${e.toString()}');
      }
    }
  }
  
  /// Behandelt Fehler bei HTTP-Anfragen
  void _handleError(Object error, String method, String url) {
    if (error is SocketException) {
      _log.severe('Netzwerkfehler bei $method-Anfrage an $url: ${error.message}');
    } else if (error is TimeoutException) {
      _log.severe('Timeout bei $method-Anfrage an $url');
    } else if (error is FormatException) {
      _log.severe('Formatfehler bei $method-Anfrage an $url: ${error.message}');
    } else if (error is HttpException) {
      _log.severe('HTTP-Fehler bei $method-Anfrage an $url: ${error.message}');
    } else {
      _log.severe('Unbekannter Fehler bei $method-Anfrage an $url: $error');
    }
  }
  
  /// Prüft, ob eine HTTP-Antwort erfolgreich ist
  bool isSuccessful(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }
  
  /// Schließt den HTTP-Client
  void close() {
    _client.close();
  }
} 