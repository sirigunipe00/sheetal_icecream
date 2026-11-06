class UserAddress {
  const UserAddress({
    required this.id,
    required this.userId,
    this.label = 'Home',
    required this.recipientName,
    required this.phone,
    required this.house,
    this.street,
    required this.locality,
    this.landmark,
    this.city = 'Bengaluru',
    this.state = 'Karnataka',
    required this.postalCode,
    this.instructions,
    this.isDefault = false,
  });

  final String id;
  final String userId;
  final String label;
  final String recipientName;
  final String phone;
  final String house;
  final String? street;
  final String locality;
  final String? landmark;
  final String city;
  final String state;
  final String postalCode;
  final String? instructions;
  final bool isDefault;

  /// Returns full human-readable multi-line or single-line address string
  String get formattedAddress {
    final parts = <String>[
      house,
      if (street != null && street!.trim().isNotEmpty) street!.trim(),
      locality,
      if (landmark != null && landmark!.trim().isNotEmpty) 'Near ${landmark!.trim()}',
      '$city - $postalCode',
    ];
    return parts.join(', ');
  }

  UserAddress copyWith({
    String? id,
    String? userId,
    String? label,
    String? recipientName,
    String? phone,
    String? house,
    String? street,
    String? locality,
    String? landmark,
    String? city,
    String? state,
    String? postalCode,
    String? instructions,
    bool? isDefault,
  }) {
    return UserAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      house: house ?? this.house,
      street: street ?? this.street,
      locality: locality ?? this.locality,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      instructions: instructions ?? this.instructions,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'label': label,
      'recipient_name': recipientName,
      'phone': phone,
      'house': house,
      'street': street,
      'locality': locality,
      'landmark': landmark,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'instructions': instructions,
      'is_default': isDefault,
    };
  }

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      label: (map['label'] ?? 'Home').toString(),
      recipientName: (map['recipient_name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      house: (map['house'] ?? '').toString(),
      street: map['street']?.toString(),
      locality: (map['locality'] ?? '').toString(),
      landmark: map['landmark']?.toString(),
      city: (map['city'] ?? 'Bengaluru').toString(),
      state: (map['state'] ?? 'Karnataka').toString(),
      postalCode: (map['postal_code'] ?? '').toString(),
      instructions: map['instructions']?.toString(),
      isDefault: map['is_default'] == true,
    );
  }
}

