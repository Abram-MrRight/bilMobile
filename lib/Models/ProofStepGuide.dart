class ProofStep {
  final int stepNumber;
  final String title;
  final String description;
  final String icon;
  final String color;

  ProofStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory ProofStep.fromJson(Map<String, dynamic> json) {
    return ProofStep(
      stepNumber: json['step_number'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'step_number': stepNumber,
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
    };
  }
}
