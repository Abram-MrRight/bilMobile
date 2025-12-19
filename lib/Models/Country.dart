class Country {
  final int id;
  final String name;
  final String code; // this is the currency code

  Country({required this.id, required this.name, required this.code});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'],
      name: json['name'],
      code: json['code'], // map currency code here
    );
  }
}
