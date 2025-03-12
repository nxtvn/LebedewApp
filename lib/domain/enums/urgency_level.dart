enum UrgencyLevel {
  low(
    label: 'Niedrig',
    description: 'Das Problem beeinträchtigt die Nutzung des Geräts nicht wesentlich. Eine Bearbeitung innerhalb der nächsten Woche ist ausreichend.',
  ),
  medium(
    label: 'Mittel',
    description: 'Das Problem beeinträchtigt die Nutzung des Geräts teilweise. Eine Bearbeitung innerhalb der nächsten 2-3 Tage ist wünschenswert.',
  ),
  high(
    label: 'Hoch',
    description: 'Das Problem verhindert die Nutzung des Geräts vollständig. Eine schnellstmögliche Bearbeitung ist erforderlich.',
  );

  final String label;
  final String description;
  
  const UrgencyLevel({
    required this.label,
    required this.description,
  });
} 