import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lebedew_app/domain/repositories/trouble_report_repository.dart';
import 'package:lebedew_app/domain/entities/trouble_report.dart';
import 'package:lebedew_app/domain/enums/request_type.dart';
import 'package:lebedew_app/domain/enums/urgency_level.dart';
import 'package:lebedew_app/presentation/common/viewmodels/trouble_report_viewmodel.dart';

// Generiere Mock-Klassen
@GenerateMocks([TroubleReportRepository])
import 'trouble_report_viewmodel_test.mocks.dart';

void main() {
  late TroubleReportViewModel viewModel;
  late MockTroubleReportRepository mockRepository;

  setUp(() {
    mockRepository = MockTroubleReportRepository();
    viewModel = TroubleReportViewModel(mockRepository);
  });

  test('TroubleReportViewModel sollte mit Standardwerten initialisiert werden', () {
    expect(viewModel.name, isNull);
    expect(viewModel.email, isNull);
    expect(viewModel.phone, isNull);
    expect(viewModel.address, isNull);
    expect(viewModel.description, isNull);
    expect(viewModel.type, equals(RequestType.trouble));
    expect(viewModel.urgencyLevel, equals(UrgencyLevel.medium));
    expect(viewModel.hasMaintenanceContract, isFalse);
    expect(viewModel.energySources, isEmpty);
    expect(viewModel.images, isEmpty);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.error, isNull);
  });

  test('TroubleReportViewModel sollte Werte setzen können', () {
    viewModel.setName('Test User');
    viewModel.setEmail('test@example.com');
    viewModel.setPhone('123456789');
    viewModel.setAddress('Test Address');
    viewModel.setDescription('Test Description');
    viewModel.setType(RequestType.maintenance);
    viewModel.setUrgencyLevel(UrgencyLevel.high);
    viewModel.setHasMaintenanceContract(true);
    viewModel.setEnergySources(['Gas', 'Strom']);

    expect(viewModel.name, equals('Test User'));
    expect(viewModel.email, equals('test@example.com'));
    expect(viewModel.phone, equals('123456789'));
    expect(viewModel.address, equals('Test Address'));
    expect(viewModel.description, equals('Test Description'));
    expect(viewModel.type, equals(RequestType.maintenance));
    expect(viewModel.urgencyLevel, equals(UrgencyLevel.high));
    expect(viewModel.hasMaintenanceContract, isTrue);
    expect(viewModel.energySources, equals(['Gas', 'Strom']));
  });

  test('TroubleReportViewModel sollte zurückgesetzt werden können', () {
    viewModel.setName('Test User');
    viewModel.setEmail('test@example.com');
    viewModel.reset();

    expect(viewModel.name, isNull);
    expect(viewModel.email, isNull);
    expect(viewModel.type, equals(RequestType.trouble));
    expect(viewModel.urgencyLevel, equals(UrgencyLevel.medium));
  });

  test('TroubleReportViewModel sollte eine Störungsmeldung erstellen können', () {
    viewModel.setName('Test User');
    viewModel.setEmail('test@example.com');
    viewModel.setDescription('Test Description');

    final report = viewModel.createReport();

    expect(report.name, equals('Test User'));
    expect(report.email, equals('test@example.com'));
    expect(report.description, equals('Test Description'));
    expect(report.type, equals(RequestType.trouble));
    expect(report.urgencyLevel, equals(UrgencyLevel.medium));
  });

  test('TroubleReportViewModel sollte eine Störungsmeldung senden können', () async {
    // Konfiguriere den Mock
    when(mockRepository.submitTroubleReport(any, any))
        .thenAnswer((_) async => true);

    viewModel.setName('Test User');
    viewModel.setEmail('test@example.com');
    viewModel.setDescription('Test Description');

    final success = await viewModel.submitReport();

    expect(success, isTrue);
    verify(mockRepository.submitTroubleReport(any, any)).called(1);
  });

  test('TroubleReportViewModel sollte Fehler beim Senden behandeln', () async {
    // Konfiguriere den Mock, um einen Fehler zu simulieren
    when(mockRepository.submitTroubleReport(any, any))
        .thenAnswer((_) async => false);

    viewModel.setName('Test User');
    viewModel.setEmail('test@example.com');
    viewModel.setDescription('Test Description');

    final success = await viewModel.submitReport();

    expect(success, isFalse);
    verify(mockRepository.submitTroubleReport(any, any)).called(1);
  });
} 