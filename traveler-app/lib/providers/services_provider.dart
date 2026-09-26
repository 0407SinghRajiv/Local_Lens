import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/config_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService();
});
