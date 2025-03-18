import 'package:json_annotation/json_annotation.dart';

/// Typ der Anfrage
@JsonEnum()
enum RequestType {
  @JsonValue('trouble')
  trouble,
  
  @JsonValue('maintenance')
  maintenance,
  
  @JsonValue('installation')
  installation,
  
  @JsonValue('question')
  question,
  
  @JsonValue('consultation')
  consultation,
  
  @JsonValue('other')
  other;
  
  String get displayName {
    switch (this) {
      case RequestType.trouble:
        return 'Störung';
      case RequestType.maintenance:
        return 'Wartung';
      case RequestType.installation:
        return 'Installation';
      case RequestType.question:
        return 'Frage';
      case RequestType.consultation:
        return 'Beratung';
      case RequestType.other:
        return 'Sonstiges';
    }
  }
  
  /// Alias für displayName, für Kompatibilität mit existierendem Code
  String get label => displayName;
} 