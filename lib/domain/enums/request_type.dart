enum RequestType {
  trouble(label: 'Störungsmeldung'),
  maintenance(label: 'Wartungsanfrage'),
  installation(label: 'Installationsanfrage'),
  consultation(label: 'Beratungsanfrage'),
  other(label: 'Sonstiges');

  final String label;
  const RequestType({required this.label});
} 