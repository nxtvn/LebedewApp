import '../../../domain/entities/trouble_report.dart';
import '../../../domain/repositories/trouble_report_repository.dart';
import '../../../domain/enums/request_type.dart';
import '../../../domain/enums/urgency_level.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/utils/image_utils.dart';
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
  String? _deviceModel;
  String? _manufacturer;
  String? _serialNumber;
  String? _errorCode;
  DateTime? _occurrenceDate;
  String? _serviceHistory;
  String? _previousIssues;
  UrgencyLevel _urgencyLevel = UrgencyLevel.medium;

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
  String? get deviceModel => _deviceModel;
  String? get manufacturer => _manufacturer;
  String? get serialNumber => _serialNumber;
  String? get errorCode => _errorCode;
  DateTime? get occurrenceDate => _occurrenceDate;
  String? get serviceHistory => _serviceHistory;
  String? get previousIssues => _previousIssues;
  UrgencyLevel get urgencyLevel => _urgencyLevel;
  
  /// Prüft, ob die Störungsmeldung gültig ist und gesendet werden kann
  bool get isValid => _name != null && _name!.isNotEmpty && 
                      _email != null && _email!.isNotEmpty && 
                      _description != null && _description!.isNotEmpty;

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
      final report = createReport();
      return await _repository.submitReport(report, _images);
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
      return await _repository.submitTroubleReport(report);
    }) ?? false;
  }

  /// Wählt ein Bild aus der Galerie oder Kamera aus
  ///
  /// [source] gibt an, ob das Bild aus der Galerie oder der Kamera stammt
  Future<void> pickImage(ImageSource source) async {
    try {
      setLoading();
      
      if (source == ImageSource.gallery) {
        await _pickMultipleImages();
      } else {
        await _pickSingleImage(source);
      }
      
      setLoaded();
    } catch (e) {
      setError('Fehler beim Auswählen des Bildes: $e');
      debugPrint('Fehler beim Bildauswahl: $e');
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
    _deviceModel = null;
    _manufacturer = null;
    _serialNumber = null;
    _errorCode = null;
    _energySources = {};
    _occurrenceDate = null;
    _serviceHistory = null;
    _previousIssues = null;
    _urgencyLevel = UrgencyLevel.medium;
    _imagesPaths.clear();
    _images.clear();
    
    notifyListeners();
  }
} 