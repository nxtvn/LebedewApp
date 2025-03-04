enum UrgencyLevel {
  high('Hoch', 'Totalausfall (z.B. Heizung im Winter)'),
  medium('Mittel', 'Eingeschränkte Funktion'),
  low('Niedrig', 'Kleinere Unregelmäßigkeiten');

  final String label;
  final String description;
  const UrgencyLevel(this.label, this.description);
} 