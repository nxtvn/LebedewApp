class TroubleReport {
  final String name;
  final String email;
  final String description;
  final List<String> imagesPaths;

  TroubleReport({
    required this.name,
    required this.email,
    required this.description,
    required this.imagesPaths,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'description': description,
    'imagesPaths': imagesPaths,
  };
} 