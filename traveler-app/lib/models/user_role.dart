enum UserRole {
  traveler,
  provider,
  rider,
  admin;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.traveler;
    switch (role.toLowerCase().trim()) {
      case 'provider':
        return UserRole.provider;
      case 'rider':
        return UserRole.rider;
      case 'admin':
        return UserRole.admin;
      case 'traveler':
      default:
        return UserRole.traveler;
    }
  }

  String get value => name;
}
