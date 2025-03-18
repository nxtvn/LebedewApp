import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lebedew_app/domain/repositories/trouble_report_repository.dart';
import 'dart:io';

// Generiere Mock-Klassen mit benutzerdefinierten Namen
@GenerateMocks([TroubleReportRepository])
// Nach der Generierung muss dieser Import aktiviert werden
// import 'trouble_report_viewmodel_test.mocks.dart';

// Mock für File-Objekte, da wir keine echten Dateien in Tests verwenden können
class MockFile extends Mock implements File {
  @override
  final String path;
  
  MockFile(this.path);
  
  @override
  String toString() => 'MockFile: $path';
}

// Tests werden hier auskommentiert, bis die Mocks korrekt generiert wurden
// void main() {
//   late TroubleReportViewModel viewModel;
//   late MockTroubleReportRepository mockRepository;
// 
//   setUp(() {
//     mockRepository = MockTroubleReportRepository();
//     viewModel = TroubleReportViewModel(mockRepository);
//   });
// 
//   test('TroubleReportViewModel sollte mit Standardwerten initialisiert werden', () {
//     expect(viewModel.name, isNull);
//     expect(viewModel.email, isNull);
//     expect(viewModel.phone, isNull);
//     expect(viewModel.address, isNull);
//     expect(viewModel.description, isNull);
//     expect(viewModel.type, equals(RequestType.trouble));
//     expect(viewModel.urgencyLevel, equals(UrgencyLevel.medium));
//     expect(viewModel.hasMaintenanceContract, isFalse);
//     expect(viewModel.energySources, isEmpty);
//     expect(viewModel.images, isEmpty);
//     expect(viewModel.isLoading, isFalse);
//     // expect(viewModel.error, isNull);
//   });
// }

// Leere Main-Funktion, um build_runner zu ermöglichen, die Mocks zu generieren
void main() {} 