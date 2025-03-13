import '../../../domain/entities/trouble_report.dart';
import '../../../domain/repositories/trouble_report_repository.dart';
import '../../../domain/enums/request_type.dart';
import '../../../domain/enums/urgency_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import '../../../core/utils/image_utils.dart';
import '../../../core/network/network_info_facade.dart';
import '../../../data/services/email_queue_service.dart';
import 'package:get_it/get_it.dart';
import 'base_viewmodel.dart';

/// ViewModel für die Störungsmeldung
///
/// Dieses ViewModel dient als Vermittler zwischen der UI und dem Repository.
/// Es verwaltet den Zustand der Störungsmeldung und bietet Methoden zum Bearbeiten
/// und Absenden der Daten.
class TroubleReportViewModel extends BaseViewModel {
  final TroubleReportRepository _repository;
  final ImagePicker _picker = ImagePicker();
  
  // Formularfelder
  String? _name;
  String? _email;
  String? _phone;
  String? _address;
  RequestType _type = RequestType.trouble;
  String? _description;
  final List<String> _imagesPaths = [];
  final List<File> _images = [];
  Set<String> _energySources = {};
  bool _hasMaintenanceContract = false;
  String? _customerNumber;
  String? _deviceModel;
  String? _manufacturer;
  String? _serialNumber;
  String? _errorCode;
  DateTime? _occurrenceDate;
  String? _serviceHistory;
  String? _previousIssues;
  UrgencyLevel _urgencyLevel = UrgencyLevel.medium;
  bool _hasAcceptedTerms = false;

  /// Erstellt eine neue Instanz des TroubleReportViewModel
  TroubleReportViewModel(this._repository);

  // Getters
  String? get name => _name;
  String? get email => _email;
  String? get phone => _phone;
  String? get address => _address;
  RequestType get type => _type;
  String? get description => _description;
  List<File> get images => List.unmodifiable(_images);
  List<String> get imagesPaths => List.unmodifiable(_imagesPaths);
  Set<String> get energySources => _energySources;
  bool get hasMaintenanceContract => _hasMaintenanceContract;
  String? get customerNumber => _customerNumber;
  String? get deviceModel => _deviceModel;
  String? get manufacturer => _manufacturer;
  String? get serialNumber => _serialNumber;
  String? get errorCode => _errorCode;
  DateTime? get occurrenceDate => _occurrenceDate;
  String? get serviceHistory => _serviceHistory;
  String? get previousIssues => _previousIssues;
  UrgencyLevel get urgencyLevel => _urgencyLevel;
  bool get hasAcceptedTerms => _hasAcceptedTerms;
  
  /// Prüft, ob die Störungsmeldung gültig ist und gesendet werden kann
  bool get isValid => _name != null && _name!.isNotEmpty && 
                      _email != null && _email!.isNotEmpty && 
                      _description != null && _description!.isNotEmpty &&
                      _hasAcceptedTerms &&
                      (!_hasMaintenanceContract || (_customerNumber != null && _customerNumber!.isNotEmpty));

  /// Generische Setter-Methode für String-Felder
  /// 
  /// [field] ist der Name des Feldes, das gesetzt werden soll
  /// [value] ist der neue Wert
  /// [notify] gibt an, ob die UI über die Änderung informiert werden soll
  void setStringField(String field, String? value, {bool notify = false}) {
    switch (field) {
      case 'name':
        _name = value;
      case 'email':
        _email = value;
      case 'phone':
        _phone = value;
      case 'address':
        _address = value;
      case 'description':
        if (_description != value) {
          _description = value;
        }
      case 'customerNumber':
        if (_customerNumber != value) {
          _customerNumber = value;
        }
      case 'deviceModel':
        if (_deviceModel != value) {
          _deviceModel = value;
        }
      case 'manufacturer':
        if (_manufacturer != value) {
          _manufacturer = value;
        }
      case 'serialNumber':
        if (_serialNumber != value) {
          _serialNumber = value;
        }
      case 'errorCode':
        if (_errorCode != value) {
          _errorCode = value;
        }
      case 'serviceHistory':
        _serviceHistory = value;
      case 'previousIssues':
        if (_previousIssues != value) {
          _previousIssues = value;
        }
      default:
        debugPrint('Unbekanntes Feld: $field');
        return;
    }
    
    if (notify) {
      notifyListeners();
    }
  }

  // Spezifische Setter für komplexere Typen
  void setName(String? value) => setStringField('name', value);
  void setEmail(String? value) => setStringField('email', value);
  void setPhone(String? value) => setStringField('phone', value);
  void setAddress(String? value) => setStringField('address', value);
  void setDescription(String? value) => setStringField('description', value);
  void setCustomerNumber(String? value) => setStringField('customerNumber', value, notify: true);
  void setDeviceModel(String? value) => setStringField('deviceModel', value);
  void setManufacturer(String? value) => setStringField('manufacturer', value);
  void setSerialNumber(String? value) => setStringField('serialNumber', value);
  void setErrorCode(String? value) => setStringField('errorCode', value);
  void setServiceHistory(String? value) => setStringField('serviceHistory', value, notify: true);
  void setPreviousIssues(String? value) => setStringField('previousIssues', value);

  void setType(RequestType? value) {
    if (value != null && _type != value) {
      _type = value;
      notifyListeners();
    }
  }

  void setUrgencyLevel(UrgencyLevel? value) {
    if (value != null && _urgencyLevel != value) {
      _urgencyLevel = value;
      notifyListeners();
    }
  }

  void setEnergySources(Set<String> value) {
    _energySources = value;
    notifyListeners();
  }

  void setHasMaintenanceContract(bool value) {
    if (_hasMaintenanceContract != value) {
      _hasMaintenanceContract = value;
      notifyListeners();
    }
  }

  void setHasAcceptedTerms(bool value) {
    if (_hasAcceptedTerms != value) {
      _hasAcceptedTerms = value;
      notifyListeners();
    }
  }

  void setOccurrenceDate(DateTime? value) {
    if (_occurrenceDate != value) {
      _occurrenceDate = value;
      notifyListeners();
    }
  }

  /// Fügt ein Bild zur Störungsmeldung hinzu
  ///
  /// [path] ist der Pfad zum Bild
  void addImagePath(String path) {
    _imagesPaths.add(path);
    _images.add(File(path));
    notifyListeners();
  }

  /// Entfernt ein Bild aus der Störungsmeldung
  ///
  /// [index] ist der Index des zu entfernenden Bildes
  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      _imagesPaths.removeAt(index);
      notifyListeners();
    }
  }

  /// Erstellt eine TroubleReport-Entität aus den aktuellen ViewModel-Daten
  TroubleReport createReport() {
    return TroubleReport(
      type: _type,
      name: _name ?? '',
      email: _email ?? '',
      phone: _phone,
      address: _address,
      hasMaintenanceContract: _hasMaintenanceContract,
      customerNumber: _customerNumber,
      description: _description ?? '',
      deviceModel: _deviceModel,
      manufacturer: _manufacturer,
      serialNumber: _serialNumber,
      errorCode: _errorCode,
      energySources: _energySources,
      occurrenceDate: _occurrenceDate,
      serviceHistory: _serviceHistory,
      urgencyLevel: _urgencyLevel,
      imagesPaths: _imagesPaths,
      hasAcceptedTerms: _hasAcceptedTerms,
    );
  }

  /// Sendet die Störungsmeldung an das Repository
  ///
  /// Verwendet die BaseViewModel-Methode runAsyncOperation für konsistente Fehlerbehandlung
  /// Gibt true zurück, wenn die Störungsmeldung erfolgreich gesendet wurde, sonst false
  Future<bool> submitReport() async {
    if (!isValid) {
      setError('Bitte füllen Sie alle erforderlichen Felder aus.');
      return false;
    }

    return await runAsyncOperation<bool>(() async {
      try {
        // Prüfe Netzwerkverbindung
        final networkInfo = GetIt.I<NetworkInfoFacade>();
        final isConnected = await networkInfo.isCurrentlyConnected;
        
        // Erstelle Report-Objekt
        final report = createReport();
        
        if (!isConnected) {
          // Offline-Fallback: Speichere in Queue
          await GetIt.I<EmailQueueService>().addToQueue(
            report,
            _images.map((image) => image.path).toList(),
          );
          
          return true; // Gib Erfolg zurück, da wir es später senden werden
        }
        
        // Online: Normal fortfahren
        final success = await _repository.submitReport(report, _images);
        
        if (!success) {
          throw Exception('Die Störungsmeldung konnte nicht gesendet werden. Bitte versuchen Sie es später erneut.');
        }
        
        return success;
      } on SocketException {
        // Speichere in Queue für später
        final report = createReport();
        await GetIt.I<EmailQueueService>().addToQueue(
          report,
          _images.map((image) => image.path).toList(),
        );
        
        throw Exception('Keine Internetverbindung. Ihre Meldung wurde gespeichert und wird automatisch gesendet, sobald eine Verbindung verfügbar ist.');
      } on TimeoutException {
        // Speichere in Queue für später
        final report = createReport();
        await GetIt.I<EmailQueueService>().addToQueue(
          report,
          _images.map((image) => image.path).toList(),
        );
        
        throw Exception('Die Anfrage hat zu lange gedauert. Ihre Meldung wurde gespeichert und wird automatisch erneut gesendet.');
      } catch (e) {
        debugPrint('Fehler beim Senden der Störungsmeldung: $e');
        throw Exception('Ein unerwarteter Fehler ist aufgetreten. Bitte versuchen Sie es später erneut.');
      }
    }) ?? false;
  }

  /// Sendet eine optimierte Störungsmeldung an das Repository
  ///
  /// Die Bilder werden vor dem Senden optimiert, um die Übertragungszeit zu verkürzen
  /// Gibt true zurück, wenn die Störungsmeldung erfolgreich gesendet wurde, sonst false
  Future<bool> submitOptimizedReport() async {
    if (!isValid) {
      setError('Bitte füllen Sie alle erforderlichen Felder aus.');
      return false;
    }

    return await runAsyncOperation<bool>(() async {
      try {
        TroubleReport report = createReport();
        
        // Optimize images if available
        if (report.imagesPaths.isNotEmpty) {
          final optimizedImagePaths = <String>[];
          
          for (final imagePath in report.imagesPaths) {
            try {
              final image = File(imagePath);
              final optimizedImage = await ImageUtils.optimizeImage(image);
              optimizedImagePaths.add(optimizedImage.path);
            } catch (e) {
              // If optimization fails, use original image path
              optimizedImagePaths.add(imagePath);
              debugPrint('Bildoptimierung fehlgeschlagen: $e');
            }
          }
          
          // Update report with optimized image paths
          report = report.copyWith(imagesPaths: optimizedImagePaths);
        }
        
        // Submit report to repository
        final success = await _repository.submitTroubleReport(report);
        
        if (!success) {
          throw Exception('Die Störungsmeldung konnte nicht gesendet werden. Bitte versuchen Sie es später erneut.');
        }
        
        return success;
      } on SocketException {
        throw Exception('Keine Internetverbindung. Bitte überprüfen Sie Ihre Netzwerkeinstellungen und versuchen Sie es erneut.');
      } on TimeoutException {
        throw Exception('Die Anfrage hat zu lange gedauert. Bitte versuchen Sie es später erneut.');
      } catch (e) {
        debugPrint('Fehler beim Senden der optimierten Störungsmeldung: $e');
        throw Exception('Ein unerwarteter Fehler ist aufgetreten. Bitte versuchen Sie es später erneut.');
      }
    }) ?? false;
  }

  /// Fordert Berechtigungen für Kamera und Speicher an
  ///
  /// Gibt true zurück, wenn beide Berechtigungen erteilt wurden, sonst false
  Future<bool> requestPermissions() async {
    // Prüfe zuerst den aktuellen Status der Berechtigungen
    final cameraStatus = await Permission.camera.status;
    final storageStatus = Platform.isAndroid && await Permission.storage.status.isGranted
        ? await Permission.storage.status
        : await Permission.photos.status;
    
    // Wenn bereits alle Berechtigungen erteilt wurden, gib true zurück
    if (cameraStatus.isGranted && (storageStatus.isGranted || storageStatus.isLimited)) {
      return true;
    }
    
    // Wenn Berechtigungen permanent verweigert wurden, zeige einen Dialog an
    if (cameraStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      setError('Einige Berechtigungen wurden dauerhaft verweigert. Bitte öffnen Sie die App-Einstellungen, um die Berechtigungen manuell zu erteilen.');
      return false;
    }
    
    // Fordere die Berechtigungen an
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Platform.isAndroid ? Permission.storage : Permission.photos,
    ].request();
    
    // Prüfe, ob alle Berechtigungen erteilt wurden
    final cameraGranted = statuses[Permission.camera]!.isGranted;
    final storageGranted = Platform.isAndroid 
        ? statuses[Permission.storage]!.isGranted 
        : (statuses[Permission.photos]!.isGranted || statuses[Permission.photos]!.isLimited);
    
    return cameraGranted && storageGranted;
  }
  
  /// Zeigt einen Dialog an, der erklärt, warum die App bestimmte Berechtigungen benötigt
  ///
  /// [context] ist der BuildContext, der für den Dialog benötigt wird
  /// [permission] ist die Berechtigung, für die der Dialog angezeigt wird
  Future<bool> showPermissionDialog(BuildContext context, Permission permission) async {
    String title = 'Berechtigung erforderlich';
    String message = '';
    
    switch (permission) {
      case Permission.camera:
        title = 'Kamerazugriff erforderlich';
        message = 'Die App benötigt Zugriff auf die Kamera, um Fotos für die Dokumentation von Störungen aufzunehmen. Diese Fotos helfen unseren Technikern, das Problem besser zu verstehen.';
        break;
      case Permission.storage:
      case Permission.photos:
        title = 'Fotogalerie-Zugriff erforderlich';
        message = 'Die App benötigt Zugriff auf Ihre Fotos, um bestehende Bilder für Störungsmeldungen auszuwählen. Diese Bilder helfen unseren Technikern, das Problem besser zu verstehen.';
        break;
      case Permission.location:
        title = 'Standortzugriff erforderlich';
        message = 'Für die Ortsbestimmung bei Störungsmeldungen, um den Service-Technikern Ihren Standort mitzuteilen. Dies ermöglicht eine schnellere Bearbeitung Ihrer Anfrage.';
        break;
      default:
        message = 'Diese Berechtigung wird benötigt, um die App ordnungsgemäß zu nutzen.';
    }
    
    // Zeige den Dialog an
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Ablehnen'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Zulassen'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Wählt ein Bild aus der Galerie oder Kamera aus
  ///
  /// [source] gibt an, ob das Bild aus der Galerie oder der Kamera stammt
  /// [context] ist der BuildContext, der für Dialoge benötigt wird
  Future<void> pickImage(ImageSource source, [BuildContext? context]) async {
    try {
      setLoading();
      
      // Berechtigungen anfordern
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        // Wenn der Kontext verfügbar ist, zeige einen Dialog an
        if (context != null) {
          final Permission permission = source == ImageSource.camera 
              ? Permission.camera 
              : (Platform.isAndroid ? Permission.storage : Permission.photos);
          
          // Prüfe, ob der Widget-Baum noch montiert ist, bevor der Dialog angezeigt wird
          if (context.mounted) {
            final userWantsPermission = await showPermissionDialog(context, permission);
            
            if (userWantsPermission) {
              // Öffne die App-Einstellungen
              await openAppSettings();
            }
          }
        } else {
          setError('Berechtigungen wurden verweigert. Bitte erteilen Sie die erforderlichen Berechtigungen in den Einstellungen.');
        }
        return;
      }
      
      if (source == ImageSource.gallery) {
        await _pickMultipleImages();
      } else {
        await _pickSingleImage(source);
      }
      
      setLoaded();
    } catch (e) {
      String errorMessage = 'Fehler beim Auswählen des Bildes';
      
      if (e is PlatformException) {
        if (e.code == 'camera_access_denied') {
          errorMessage = 'Kamerazugriff verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen.';
        } else if (e.code == 'photo_access_denied') {
          errorMessage = 'Zugriff auf Fotos verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen.';
        } else if (e.code == 'permission_denied') {
          errorMessage = 'Berechtigung verweigert. Bitte erlauben Sie den Zugriff in den Einstellungen.';
        }
      }
      
      setError(errorMessage);
      debugPrint('Fehler bei der Bildauswahl: $e');
    }
  }

  /// Wählt mehrere Bilder aus der Galerie aus
  Future<void> _pickMultipleImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      for (final file in pickedFiles) {
        await _processPickedImage(file);
      }
    }
  }

  /// Wählt ein einzelnes Bild aus der Kamera aus
  Future<void> _pickSingleImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      await _processPickedImage(pickedFile);
    }
  }

  /// Verarbeitet ein ausgewähltes Bild
  Future<void> _processPickedImage(XFile file) async {
    final imageFile = File(file.path);
    _images.add(imageFile);
    final path = await _repository.saveImage(imageFile);
    _imagesPaths.add(path);
    notifyListeners();
  }

  /// Zeigt einen Ladedialog an
  ///
  /// [context] ist der BuildContext, in dem der Dialog angezeigt werden soll
  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Störungsmeldung wird gesendet...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Setzt alle Felder auf ihre Standardwerte zurück
  @override
  void reset() {
    super.reset();
    
    _type = RequestType.trouble;
    _name = null;
    _email = null;
    _phone = null;
    _address = null;
    _hasMaintenanceContract = false;
    _description = null;
    _customerNumber = null;
    _deviceModel = null;
    _manufacturer = null;
    _serialNumber = null;
    _errorCode = null;
    _energySources = {};
    _occurrenceDate = null;
    _serviceHistory = null;
    _previousIssues = null;
    _urgencyLevel = UrgencyLevel.medium;
    _hasAcceptedTerms = false;
    _imagesPaths.clear();
    _images.clear();
    
    notifyListeners();
  }
} 