import 'package:json_annotation/json_annotation.dart';

/// Dringlichkeitsstufe einer Störung
@JsonEnum()
enum UrgencyLevel {
  @JsonValue('low')
  low,
  
  @JsonValue('medium')
  medium,
  
  @JsonValue('high')
  high,
  
  @JsonValue('critical')
  critical;
  
  String get displayName {
    switch (this) {
      case UrgencyLevel.low:
        return 'Niedrig';
      case UrgencyLevel.medium:
        return 'Mittel';
      case UrgencyLevel.high:
        return 'Hoch';
      case UrgencyLevel.critical:
        return 'Kritisch';
    }
  }
  
  int get priority {
    switch (this) {
      case UrgencyLevel.low:
        return 1;
      case UrgencyLevel.medium:
        return 2;
      case UrgencyLevel.high:
        return 3;
      case UrgencyLevel.critical:
        return 4;
    }
  }
  
  /// Alias für displayName, für Kompatibilität mit existierendem Code
  String get label => displayName;
  
  /// Beschreibung der Dringlichkeitsstufe
  String get description {
    switch (this) {
      case UrgencyLevel.low:
        return 'Niedrige Priorität, Bearbeitung innerhalb einer Woche';
      case UrgencyLevel.medium:
        return 'Mittlere Priorität, Bearbeitung innerhalb von 2-3 Tagen';
      case UrgencyLevel.high:
        return 'Hohe Priorität, Bearbeitung innerhalb von 24 Stunden';
      case UrgencyLevel.critical:
        return 'Kritische Priorität, sofortige Bearbeitung';
    }
  }
} 