import 'package:flutter/foundation.dart';
import '../models/driver.dart';

/// Abstract driver repository for future Supabase integration
abstract class DriverRepository {
  Future<Driver> getDriver(String id);
  Future<void> updateDriver(Driver driver);
  Future<void> updateLocation(String driverId, double lat, double lng);
  Future<void> setOnlineStatus(String driverId, bool isOnline);
}

/// Mock driver repository
class MockDriverRepository extends DriverRepository {
  Driver? _driver;

  @override
  Future<Driver> getDriver(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _driver ??= Driver.mock();
    return _driver!;
  }

  @override
  Future<void> updateDriver(Driver driver) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _driver = driver;
    debugPrint('[MockDriverRepo] Driver updated: ${driver.name}');
  }

  @override
  Future<void> updateLocation(String driverId, double lat, double lng) async {
    if (_driver != null && _driver!.id == driverId) {
      _driver = _driver!.copyWith(
        latitude: lat,
        longitude: lng,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> setOnlineStatus(String driverId, bool isOnline) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_driver != null && _driver!.id == driverId) {
      _driver = _driver!.copyWith(
        isOnline: isOnline,
        isAvailable: isOnline,
      );
    }
    debugPrint('[MockDriverRepo] Online status: $isOnline');
  }
}
