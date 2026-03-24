class AddressModel {
  const AddressModel({
    required this.id,
    required this.label,
    required this.contactName,
    required this.phone,
    required this.line1,
    required this.city,
    required this.isDefault,
  });

  final int id;
  final String label;
  final String contactName;
  final String phone;
  final String line1;
  final String city;
  final bool isDefault;

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label: (json['label'] ?? '').toString().trim(),
      contactName: (json['contact_name'] ?? '').toString().trim(),
      phone: (json['phone'] ?? '').toString().trim(),
      line1: (json['line1'] ?? '').toString().trim(),
      city: (json['city'] ?? '').toString().trim(),
      isDefault: json['is_default'] == true,
    );
  }

  String get title {
    if (label.isNotEmpty) return label;
    if (contactName.isNotEmpty) return contactName;
    return 'Direccion #$id';
  }

  String get subtitle {
    final parts = <String>[];
    if (contactName.isNotEmpty) parts.add(contactName);
    if (line1.isNotEmpty) parts.add(line1);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(' · ');
  }
}
