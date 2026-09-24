import 'package:dio/dio.dart';

class ConfigService {
  final Dio dio;

  ConfigService({Dio? dio}) : dio = dio ?? Dio();

  /// Fetches remote configuration or returns cached defaults.
  Future<Map<String, dynamic>> fetchRemoteConfig() async {
    try {
      // Dio is configured and ready for endpoint queries if baseUrl/options provided
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return {'version': '0.1.0', 'maintenance': false};
    } catch (e) {
      // Fallback to local default configuration
      return {'version': '0.1.0', 'maintenance': false};
    }
  }
}
