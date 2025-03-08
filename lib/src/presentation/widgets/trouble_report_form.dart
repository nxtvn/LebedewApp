import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../domain/enums/request_type.dart';
import '../../domain/enums/urgency_level.dart';
import '../viewmodels/trouble_report_viewmodel.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';

/// TroubleReportForm Widget zur plattformspezifischen Darstellung des Formulars
class TroubleReportForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback? onSubmit;
  final bool showSubmitButton;
  
  const TroubleReportForm({
    required this.formKey,
    this.onSubmit,
    this.showSubmitButton = true,
    super.key,
  });

  @override
  State<TroubleReportForm> createState() => TroubleReportFormState();
}

class TroubleReportFormState extends State<TroubleReportForm> {
  // Controller für Formularfelder
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _deviceModelController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _deviceModelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Zurücksetzen des Formulars
  void reset() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _deviceModelController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoForm(context) : _buildMaterialForm(context);
  }

  /// Cupertino Formular für iOS
  Widget _buildCupertinoForm(BuildContext context) {
    final viewModel = Provider.of<TroubleReportViewModel>(context);
    
    return SafeArea(
        child: Form(
          key: widget.formKey,
        child: Container(
          color: CupertinoColors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Art der Anfrage
                CupertinoFormSection.insetGrouped(
                  backgroundColor: CupertinoColors.white,
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
                    color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CupertinoColors.systemGrey5),
                  ),
                  header: const Text(
                    'Art der Anfrage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
                      color: CupertinoColors.secondaryLabel,
                    ),
      ),
      children: [
                    CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                            viewModel.type?.label ?? 'Bitte wählen',
                  style: TextStyle(
                              color: viewModel.type != null 
                                  ? CupertinoColors.black 
                        : CupertinoColors.systemGrey,
                              fontSize: 16,
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right, 
                            color: CupertinoColors.activeBlue,
                            size: 20,
                ),
              ],
            ),
                      onPressed: () => _showCupertinoRequestTypePicker(context, viewModel),
                    ),
                  ],
                ),
                
                // 2. Kontaktinformationen
                CupertinoFormSection.insetGrouped(
                  backgroundColor: CupertinoColors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
                    color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CupertinoColors.systemGrey5),
                  ),
                  header: const Text(
                    'Kontaktinformationen',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  children: [
                    _buildCupertinoFormRow(
                      label: 'Name',
                      child: CupertinoTextField.borderless(
                        controller: _nameController,
                        placeholder: 'Name eingeben',
                        placeholderStyle: const TextStyle(
              color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                        style: const TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 16,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onChanged: (value) => viewModel.setName(value),
                        clearButtonMode: OverlayVisibilityMode.editing,
                      ),
                    ),
                    const Divider(height: 0, thickness: 0.5, color: CupertinoColors.systemGrey5),
        _buildCupertinoFormRow(
                      label: 'E-Mail',
                      child: CupertinoTextField.borderless(
          controller: _emailController,
                        placeholder: 'E-Mail eingeben',
                        placeholderStyle: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                        style: const TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 16,
                        ),
          keyboardType: TextInputType.emailAddress,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onChanged: (value) => viewModel.setEmail(value),
                        clearButtonMode: OverlayVisibilityMode.editing,
                      ),
                    ),
                    const Divider(height: 0, thickness: 0.5, color: CupertinoColors.systemGrey5),
        _buildCupertinoFormRow(
                      label: 'Telefon',
                      child: CupertinoTextField.borderless(
          controller: _phoneController,
                        placeholder: 'Telefonnummer eingeben',
                        placeholderStyle: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                        style: const TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 16,
                        ),
          keyboardType: TextInputType.phone,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onChanged: (value) => viewModel.setPhone(value),
                        clearButtonMode: OverlayVisibilityMode.editing,
                      ),
                    ),
                    const Divider(height: 0, thickness: 0.5, color: CupertinoColors.systemGrey5),
        _buildCupertinoFormRow(
          label: 'Adresse',
                      child: CupertinoTextField.borderless(
          controller: _addressController,
                        placeholder: 'Adresse eingeben',
                        placeholderStyle: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
        style: const TextStyle(
                          color: CupertinoColors.black,
          fontSize: 16,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onChanged: (value) => viewModel.setAddress(value),
        clearButtonMode: OverlayVisibilityMode.editing,
                      ),
                    ),
                  ],
                ),
                
                // 3. Geräteinformationen
                CupertinoFormSection.insetGrouped(
                  backgroundColor: CupertinoColors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
                    color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CupertinoColors.systemGrey5),
                  ),
                  header: const Text(
                    'Geräteinformationen',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
                      color: CupertinoColors.secondaryLabel,
                    ),
      ),
      children: [
                    Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gerätemodell',
            style: TextStyle(
                              color: CupertinoColors.black,
              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CupertinoTextField(
                            controller: _deviceModelController,
                            placeholder: 'Gerätemodell eingeben',
                            placeholderStyle: const TextStyle(
                              color: CupertinoColors.systemGrey,
                  fontSize: 16,
                ),
                            style: const TextStyle(
                              color: CupertinoColors.black,
                  fontSize: 16,
                ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: CupertinoColors.systemGrey4),
                            ),
                            onChanged: (value) => viewModel.setDeviceModel(value),
                            clearButtonMode: OverlayVisibilityMode.editing,
                          ),
                        ],
                ),
              ),
            ],
          ),
                
                // 4. Auftrittsdatum
                CupertinoFormSection.insetGrouped(
                  backgroundColor: CupertinoColors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CupertinoColors.systemGrey5),
                  ),
                  header: const Text(
                    'Auftrittsdatum',
            style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                            _dateFormat.format(_selectedDate),
                            style: const TextStyle(
                              color: CupertinoColors.black,
                    fontSize: 16,
                  ),
                ),
                const Icon(
                  CupertinoIcons.calendar, 
                            color: CupertinoColors.activeBlue,
                  size: 20, 
                ),
              ],
            ),
                      onPressed: () => _showCupertinoDatePicker(context, viewModel),
                    ),
                  ],
                ),
                
                // 5. Beschreibung
                CupertinoFormSection.insetGrouped(
                  backgroundColor: CupertinoColors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
                    color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CupertinoColors.systemGrey5),
                  ),
                  header: const Text(
                    'Beschreibung',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
                      color: CupertinoColors.secondaryLabel,
                    ),
      ),
      children: [
        Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: CupertinoTextField(
                        controller: _descriptionController,
                        placeholder: 'Beschreiben Sie das Problem',
                        placeholderStyle: const TextStyle(
                          color: CupertinoColors.systemGrey,
                  fontSize: 16,
                        ),
                        style: const TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 16,
                        ),
                        padding: const EdgeInsets.all(12),
                        maxLines: 5,
                        minLines: 3,
                        onChanged: (value) => viewModel.setDescription(value),
                decoration: BoxDecoration(
                          color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CupertinoColors.systemGrey4),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 6. Fotos hinzufügen
                CupertinoFormSection.insetGrouped(
                  backgroundColor: CupertinoColors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CupertinoColors.systemGrey5),
                  ),
                  header: const Text(
                    'Fotos hinzufügen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  children: [
        Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
            children: [
                          Expanded(
                            child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                              color: CupertinoColors.activeBlue,
                              borderRadius: BorderRadius.circular(8),
                              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                                  Icon(
                                    CupertinoIcons.camera,
                                    color: CupertinoColors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                    Text(
                                    'Kamera',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                    ),
                  ],
                ),
                              onPressed: () => _pickImage(ImageSource.camera, viewModel),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              color: CupertinoColors.activeBlue,
                              borderRadius: BorderRadius.circular(8),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.photo,
                                    color: CupertinoColors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mediathek',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () => _pickImage(ImageSource.gallery, viewModel),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (viewModel.images.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
                        child: _buildCupertinoImageGallery(viewModel),
                      ),
                  ],
                ),
                
                // 7. Priorität
                CupertinoFormSection.insetGrouped(
                  backgroundColor: CupertinoColors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
                    color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CupertinoColors.systemGrey5),
                  ),
                  header: const Text(
                    'Priorität',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
                      color: CupertinoColors.secondaryLabel,
                    ),
      ),
      children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                            viewModel.urgencyLevel?.label ?? 'Mittlere Priorität',
                            style: const TextStyle(
                              color: CupertinoColors.black,
                                  fontSize: 16,
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            color: CupertinoColors.activeBlue,
                            size: 20,
                          ),
                        ],
                      ),
                      onPressed: () => _showCupertinoUrgencyPicker(context, viewModel),
                    ),
                  ],
                ),
                
                // Absenden-Button (nur anzeigen, wenn showSubmitButton true ist)
                if (widget.showSubmitButton)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: CupertinoColors.activeBlue,
                        borderRadius: BorderRadius.circular(10),
                        child: const Text(
                          'Serviceanfrage absenden',
                    style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                        onPressed: () {
                          if (_validateForm(viewModel)) {
                            widget.onSubmit?.call();
                          } else {
                            _showValidationErrorDialog(context);
                          }
                        },
                      ),
                    ),
                  ),
                
                // Abstand am Ende
                const SizedBox(height: 20),
              ],
                      ),
                    ),
                  ),
                ),
    );
  }

  /// Hilfsmethode für CupertinoFormRow mit Label und Kind
  Widget _buildCupertinoFormRow({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
          children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: child),
          ],
      ),
    );
  }

  /// Validiert das Formular für iOS
  bool _validateForm(TroubleReportViewModel viewModel) {
    // Prüfe, ob alle erforderlichen Felder ausgefüllt sind
    if (viewModel.type == null) {
      return false; // Art der Anfrage fehlt
    }
    
    if (viewModel.name == null || viewModel.name!.isEmpty) {
      return false; // Name fehlt
    }
    
    if (viewModel.email == null || viewModel.email!.isEmpty) {
      return false; // E-Mail fehlt
    }
    
    if (viewModel.phone == null || viewModel.phone!.isEmpty) {
      return false; // Telefon fehlt
    }
    
    if (viewModel.deviceModel == null || viewModel.deviceModel!.isEmpty) {
      return false; // Gerätemodell fehlt
    }
    
    if (viewModel.occurrenceDate == null) {
      return false; // Auftrittsdatum fehlt
    }
    
    if (viewModel.description == null || viewModel.description!.isEmpty) {
      return false; // Beschreibung fehlt
    }
    
    if (viewModel.urgencyLevel == null) {
      return false; // Priorität fehlt
    }
    
    return true; // Alle erforderlichen Felder sind ausgefüllt
  }

  /// Zeigt einen Validierungsfehler-Dialog an
  void _showValidationErrorDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Unvollständige Angaben',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Bitte füllen Sie alle erforderlichen Felder aus: Art der Anfrage, Name, E-Mail, Telefon, Gerätemodell, Auftrittsdatum, Beschreibung und Priorität.',
          style: TextStyle(
            fontSize: 15,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            isDefaultAction: true,
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bild aus Kamera oder Galerie auswählen
  Future<void> _pickImage(ImageSource source, TroubleReportViewModel viewModel) async {
    final picker = ImagePicker();
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> pickedFiles = await picker.pickMultiImage();
        if (pickedFiles.isNotEmpty) {
          for (final file in pickedFiles) {
            viewModel.addImagePath(file.path);
          }
        }
      } else {
        final XFile? pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null) {
          viewModel.addImagePath(pickedFile.path);
        }
      }
    } catch (e) {
      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Fehler'),
            content: const Text('Beim Auswählen des Bildes ist ein Fehler aufgetreten.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beim Auswählen des Bildes ist ein Fehler aufgetreten.'),
          ),
        );
      }
    }
  }

  /// Bild in Vollbildansicht anzeigen
  void _showFullScreenImage(BuildContext context, File image, int index, TroubleReportViewModel viewModel) {
    if (Platform.isIOS) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => CupertinoPageScaffold(
            backgroundColor: CupertinoColors.white,
            navigationBar: CupertinoNavigationBar(
              backgroundColor: CupertinoColors.white,
              middle: const Text(
                'Foto',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.trash,
                  color: CupertinoColors.systemRed,
                  ),
                    onPressed: () {
                  viewModel.removeImagePath(index);
                  Navigator.of(context).pop();
                },
              ),
            ),
            child: SafeArea(
              child: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.file(image),
                ),
              ),
            ),
        ),
      ),
    );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Foto'),
        actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
            onPressed: () {
                    viewModel.removeImagePath(index);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Image.file(image),
              ),
            ),
        ),
      ),
    );
    }
  }

  /// Cupertino Bildergalerie
  Widget _buildCupertinoImageGallery(TroubleReportViewModel viewModel) {
    if (viewModel.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Ausgewählte Fotos',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.black,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.images.length,
            itemBuilder: (context, index) {
    return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, viewModel.images[index], index, viewModel),
      child: Stack(
        children: [
                      Container(
                        width: 110,
                        height: 110,
                decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CupertinoColors.systemGrey4),
                          color: CupertinoColors.white,
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemGrey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                child: Image.file(
                            viewModel.images[index],
                  fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
                        top: 6,
                        right: 6,
            child: GestureDetector(
                          onTap: () => viewModel.removeImagePath(index),
              child: Container(
                decoration: BoxDecoration(
                              color: CupertinoColors.systemRed,
                  shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(5),
                child: const Icon(
                              CupertinoIcons.clear,
                              color: CupertinoColors.white,
                              size: 14,
                ),
              ),
            ),
          ),
        ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Cupertino Datumspicker anzeigen
  void _showCupertinoDatePicker(BuildContext context, TroubleReportViewModel viewModel) {
    // Stelle sicher, dass das Datum in der Vergangenheit liegt
    final DateTime heute = DateTime.now();
    if (_selectedDate.isAfter(heute)) {
      _selectedDate = heute;
    }
    
    // Erstelle eine Liste von Jahren (nur vergangene Jahre)
    final int currentYear = heute.year;
    final List<int> years = List.generate(
      currentYear - 1999, 
      (index) => currentYear - index
    );
    
    // Erstelle eine Liste von Monaten
    final List<String> months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    
    // Erstelle eine Liste von Tagen (1-31)
    final List<int> days = List.generate(31, (index) => index + 1);
    
    // Aktuelle Auswahl
    int selectedYear = _selectedDate.year;
    int selectedMonth = _selectedDate.month;
    int selectedDay = _selectedDate.day;
    
    // Hilfsfunktion, um zu prüfen, ob ein Datum gültig ist
    bool isValidDate(int year, int month, int day) {
      if (day > DateTime(year, month + 1, 0).day) {
        return false; // Tag existiert nicht in diesem Monat
      }
      
      final selectedDate = DateTime(year, month, day);
      return !selectedDate.isAfter(heute);
    }
    
    // Hilfsfunktion, um das ausgewählte Datum zu aktualisieren
    void updateSelectedDate() {
      // Stelle sicher, dass der Tag für den Monat gültig ist
      final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
      if (selectedDay > daysInMonth) {
        selectedDay = daysInMonth;
      }
      
      final newDate = DateTime(selectedYear, selectedMonth, selectedDay);
      
      // Stelle sicher, dass das Datum nicht in der Zukunft liegt
      if (newDate.isAfter(heute)) {
        selectedYear = heute.year;
        selectedMonth = heute.month;
        selectedDay = heute.day;
      }
      
      setState(() {
        _selectedDate = DateTime(selectedYear, selectedMonth, selectedDay);
      });
    }
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.white,
          child: SafeArea(
            top: false,
        child: Column(
              mainAxisSize: MainAxisSize.min,
          children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'Abbrechen',
                        style: TextStyle(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'Fertig',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        viewModel.setOccurrenceDate(_selectedDate);
                        Navigator.of(context).pop();
                      },
            ),
          ],
        ),
                const Divider(height: 0, thickness: 0.5, color: CupertinoColors.systemGrey4),
                Expanded(
                  child: Row(
          children: [
                      // Tag-Auswahl
                      Expanded(
                        child: CupertinoPicker(
                          backgroundColor: CupertinoColors.white,
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedDay - 1,
                          ),
                          onSelectedItemChanged: (int index) {
                            selectedDay = index + 1;
                            updateSelectedDate();
                          },
                          children: days.map((day) {
                            return Center(
                              child: Text(
                                day.toString(),
                                style: const TextStyle(
                                  color: CupertinoColors.black,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Monat-Auswahl
                      Expanded(
                        flex: 2,
                        child: CupertinoPicker(
                          backgroundColor: CupertinoColors.white,
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedMonth - 1,
                          ),
                          onSelectedItemChanged: (int index) {
                            selectedMonth = index + 1;
                            updateSelectedDate();
                          },
                          children: months.map((month) {
                            return Center(
                              child: Text(
                                month,
                                style: const TextStyle(
                                  color: CupertinoColors.black,
                                  fontSize: 16,
        ),
      ),
    );
                          }).toList(),
                        ),
                      ),
                      // Jahr-Auswahl
                      Expanded(
                        child: CupertinoPicker(
                          backgroundColor: CupertinoColors.white,
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: years.indexOf(selectedYear),
                          ),
                          onSelectedItemChanged: (int index) {
                            selectedYear = years[index];
                            updateSelectedDate();
                          },
                          children: years.map((year) {
                            return Center(
                              child: Text(
                                year.toString(),
                                style: const TextStyle(
                                  color: CupertinoColors.black,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
        );
      },
    );
  }

  /// Cupertino Anfrageart-Picker anzeigen
  void _showCupertinoRequestTypePicker(BuildContext context, TroubleReportViewModel viewModel) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.white,
          child: SafeArea(
            top: false,
      child: Column(
              mainAxisSize: MainAxisSize.min,
        children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'Abbrechen',
                        style: TextStyle(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'Fertig',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 0, thickness: 0.5, color: CupertinoColors.systemGrey4),
                          Expanded(
                  child: ListView.separated(
                    itemCount: RequestType.values.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 0,
                      thickness: 0.5,
                      color: CupertinoColors.systemGrey4,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final type = RequestType.values[index];
                      final isSelected = viewModel.type == type;
                      return CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              type.label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: CupertinoColors.black,
                                fontSize: 16,
                            ),
                          ),
                          if (isSelected)
                              const Icon(
                                CupertinoIcons.check_mark,
                                color: CupertinoColors.activeBlue,
                              ),
                          ],
                        ),
                        onPressed: () {
                          viewModel.setType(type);
                          Navigator.of(context).pop();
                        },
                      );
                    },
            ),
          ),
        ],
            ),
          ),
        );
      },
    );
  }

  /// Cupertino Dringlichkeits-Picker anzeigen
  void _showCupertinoUrgencyPicker(BuildContext context, TroubleReportViewModel viewModel) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 350,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.white,
          child: SafeArea(
            top: false,
      child: Column(
              mainAxisSize: MainAxisSize.min,
        children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'Abbrechen',
                        style: TextStyle(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'Fertig',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 0, thickness: 0.5, color: CupertinoColors.systemGrey4),
                Expanded(
                  child: ListView.separated(
                    itemCount: UrgencyLevel.values.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 0,
                      thickness: 0.5,
                      color: CupertinoColors.systemGrey4,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final level = UrgencyLevel.values[index];
                      final isSelected = viewModel.urgencyLevel == level;
                      return CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text(
                                level.label,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: CupertinoColors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  level.description,
                                  style: const TextStyle(
                    fontSize: 14,
                                    color: CupertinoColors.systemGrey,
                  ),
                ),
                              ],
              ),
                            if (isSelected)
                              const Icon(
                                CupertinoIcons.check_mark,
                                color: CupertinoColors.activeBlue,
            ),
        ],
      ),
                        onPressed: () {
                          viewModel.setUrgencyLevel(level);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          );
        },
      );
  }

  /// Material Formular für Android
  Widget _buildMaterialForm(BuildContext context) {
    final viewModel = Provider.of<TroubleReportViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // 1. Art der Anfrage
            Text(
              'Art der Anfrage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RequestType>(
              value: viewModel.type,
              decoration: const InputDecoration(
                hintText: 'Bitte wählen',
                border: OutlineInputBorder(),
              ),
              items: RequestType.values.map((type) {
                return DropdownMenuItem<RequestType>(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  viewModel.setType(value);
                }
              },
            ),
            const SizedBox(height: 20),
            
            // 2. Kontaktinformationen
            Text(
              'Kontaktinformationen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => viewModel.setName(value),
              validator: (value) => value == null || value.isEmpty ? 'Bitte geben Sie Ihren Namen ein' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => viewModel.setEmail(value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte geben Sie Ihre E-Mail-Adresse ein';
                }
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => viewModel.setPhone(value),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => viewModel.setAddress(value),
            ),
            const SizedBox(height: 20),
            
            // 3. Geräteinformationen
            Text(
              'Geräteinformationen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _deviceModelController,
              decoration: const InputDecoration(
                labelText: 'Gerätemodell',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => viewModel.setDeviceModel(value),
              validator: (value) => value == null || value.isEmpty ? 'Bitte geben Sie das Gerätemodell ein' : null,
            ),
            const SizedBox(height: 20),
            
            // 4. Auftrittsdatum
            Text(
              'Auftrittsdatum',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showMaterialDatePicker(context, viewModel),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_dateFormat.format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 20),
            
            // 5. Beschreibung
            Text(
              'Beschreibung',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreiben Sie das Problem',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              onChanged: (value) => viewModel.setDescription(value),
              validator: (value) => value == null || value.isEmpty ? 'Bitte beschreiben Sie das Problem' : null,
            ),
            const SizedBox(height: 20),
            
            // 6. Fotos hinzufügen
            Text(
              'Fotos hinzufügen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Foto aufnehmen'),
                    onPressed: () => _pickImage(ImageSource.camera, viewModel),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Aus Galerie'),
                    onPressed: () => _pickImage(ImageSource.gallery, viewModel),
            style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            // Bildergalerie
            _buildMaterialImageGallery(viewModel, colorScheme),
            
            const SizedBox(height: 20),
            
            // 7. Priorität
            Text(
              'Priorität',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Column(
              children: UrgencyLevel.values.map((level) {
                return RadioListTile<UrgencyLevel>(
                  title: Text(level.label),
                  subtitle: Text(level.description),
                  value: level,
                  groupValue: viewModel.urgencyLevel,
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.setUrgencyLevel(value);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            
            // Absenden-Button
            if (widget.showSubmitButton)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    if (_validateForm(viewModel)) {
                      widget.onSubmit?.call();
    } else {
                      _showValidationErrorDialog(context);
                    }
                  },
                  child: const Text(
                    'Serviceanfrage absenden',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ),
          ],
        ),
        ),
      );
    }

  /// Material Bildergalerie
  Widget _buildMaterialImageGallery(TroubleReportViewModel viewModel, ColorScheme colorScheme) {
    if (viewModel.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Ausgewählte Fotos',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.images.length,
            itemBuilder: (context, index) {
    return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _showFullScreenImage(context, viewModel.images[index], index, viewModel),
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            viewModel.images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => viewModel.removeImagePath(index),
                            borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
                                color: colorScheme.error,
                                shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
            ),
          ],
        ),
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.clear,
                                color: colorScheme.onError,
                                size: 14,
                              ),
                            ),
                          ),
                            ),
                          ),
                        ],
                      ),
              ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Material Datumspicker anzeigen
  Future<void> _showMaterialDatePicker(BuildContext context, TroubleReportViewModel viewModel) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      viewModel.setOccurrenceDate(picked);
    }
  }
} 