import '../../domain/entities/trouble_report.dart';
import '../../domain/repositories/trouble_report_repository.dart';
import '../../domain/enums/request_type.dart';
import '../../domain/enums/urgency_level.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/utils/image_utils.dart';
import 'base_viewmodel.dart';

class TroubleReportViewModel extends BaseViewModel {
  final TroubleReportRepository _repository;
  
  TroubleReportViewModel(this._repository);

  String? _name;
  String? _email;
  String? _phone;
  String? _address;
  RequestType? _type;
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
  UrgencyLevel? _urgencyLevel;

  bool _isLoading = false;
  String? _error;

  // Getters
  String? get name => _name;
  String? get email => _email;
  String? get phone => _phone;
  String? get address => _address;
  RequestType? get type => _type;
  String? get description => _description;
  List<File> get images => List.unmodifiable(_images);
  Set<String> get energySources => _energySources;
  bool get hasMaintenanceContract => _hasMaintenanceContract;
  String? get deviceModel => _deviceModel;
  String? get manufacturer => _manufacturer;
  String? get serialNumber => _serialNumber;
  String? get errorCode => _errorCode;
  DateTime? get occurrenceDate => _occurrenceDate;
  String? get serviceHistory => _serviceHistory;
  String? get previousIssues => _previousIssues;
  UrgencyLevel? get urgencyLevel => _urgencyLevel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TroubleReportRepository get repository => _repository;

  // Setters
  void setName(String? value) {
    _name = value;
  }

  void setEmail(String? value) {
    _email = value;
  }

  void setPhone(String? value) {
    _phone = value;
  }

  void setAddress(String? value) {
    _address = value;
  }

  void setType(RequestType? value) {
    if (_type != value) {
      _type = value;
      notifyListeners();
    }
  }

  void setDescription(String? value) {
    if (_description != value) {
      _description = value;
    }
  }

  void addImagePath(String path) {
    _imagesPaths.add(path);
    _images.add(File(path));
    notifyListeners();
  }

  void removeImagePath(int index) {
    if (index >= 0 && index < _imagesPaths.length) {
      _imagesPaths.removeAt(index);
      _images.removeAt(index);
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

  void setDeviceModel(String? value) {
    if (_deviceModel != value) {
      _deviceModel = value;
    }
  }

  void setManufacturer(String? value) {
    if (_manufacturer != value) {
      _manufacturer = value;
    }
  }

  void setSerialNumber(String? value) {
    if (_serialNumber != value) {
      _serialNumber = value;
    }
  }

  void setErrorCode(String? value) {
    if (_errorCode != value) {
      _errorCode = value;
    }
  }

  void setOccurrenceDate(DateTime? value) {
    if (_occurrenceDate != value) {
      _occurrenceDate = value;
      notifyListeners();
    }
  }

  void setServiceHistory(String? value) {
    _serviceHistory = value;
    notifyListeners();
  }

  void setPreviousIssues(String? value) {
    if (_previousIssues != value) {
      _previousIssues = value;
    }
  }

  void setUrgencyLevel(UrgencyLevel? value) {
    if (_urgencyLevel != value) {
      _urgencyLevel = value;
      notifyListeners();
    }
  }

  Future<bool> submitReport() async {
    _isLoading = true;
    notifyListeners();

    try {
      final report = TroubleReport(
        type: _type ?? RequestType.trouble,
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
        urgencyLevel: _urgencyLevel ?? UrgencyLevel.medium,
        imagesPaths: _imagesPaths,
      );

      return await _repository.submitReport(report, _images);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
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
    _urgencyLevel = UrgencyLevel.medium;
    _imagesPaths.clear();
    _images.clear();
    notifyListeners();
  }

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

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> pickedFiles = await picker.pickMultiImage();
        if (pickedFiles.isNotEmpty) {
          for (final file in pickedFiles) {
            final imageFile = File(file.path);
            _images.add(imageFile);
            final path = await _repository.saveImage(imageFile);
            _imagesPaths.add(path);
          }
          notifyListeners();
        }
      } else {
        final XFile? pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null) {
          final imageFile = File(pickedFile.path);
          _images.add(imageFile);
          final path = await _repository.saveImage(imageFile);
          _imagesPaths.add(path);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      _imagesPaths.removeAt(index);
      notifyListeners();
    }
  }

  Future<bool> submitReport(TroubleReport report) async {
    return await runAsyncOperation<bool>(() async {
      // Optimize images if available
      if (report.images.isNotEmpty) {
        final optimizedImages = <File>[];
        
        for (final image in report.images) {
          try {
            final optimizedImage = await ImageUtils.optimizeImage(image);
            optimizedImages.add(optimizedImage);
          } catch (e) {
            // If optimization fails, use original image
            optimizedImages.add(image);
            debugPrint('Image optimization failed: $e');
          }
        }
        
        // Update report with optimized images
        report = report.copyWith(images: optimizedImages);
      }
      
      // Submit report to repository
      return await _repository.submitTroubleReport(report);
    }) ?? false;
  }
} 