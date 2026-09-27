import 'package:flutter/material.dart';
import 'weather_map_screen.dart';

export 'weather_map_screen.dart';

/// Legacy alias for WeatherMapScreen to maintain compatibility across routes
class ExploreScreen extends StatelessWidget {
  final bool isStormy;
  const ExploreScreen({super.key, this.isStormy = false});

  @override
  Widget build(BuildContext context) {
    return WeatherMapScreen(isStormy: isStormy);
  }
}
