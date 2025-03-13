enum RequestType {
  trouble(label: 'Störungsmeldung'),
  maintenance(label: 'Wartungsanfrage'),
  consultation(label: 'Beratungsanfrage');

  final String label;
  const RequestType({required this.label});
} 