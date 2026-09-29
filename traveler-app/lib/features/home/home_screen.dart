import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../models/sponsored_experience.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/itinerary_provider.dart';
import '../../services/location_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/sponsor_service.dart';
import '../../services/itinerary_api_service.dart';
import '../../models/recommendation_model.dart';
import '../../widgets/common/locallens_components.dart';
import '../../widgets/active_ride_floating_bar.dart';
import '../explore/explore_screen.dart';
import '../itinerary/my_itinerary_screen.dart';
import '../saved/saved_screen.dart';
import '../profile/profile_screen.dart';
import '../rides/ride_booking_bottom_sheet.dart';

/// Screen 10: Home Screen & Main Shell with Real Sponsored Experiences
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  int _currentTabIndex = 0;
  String _selectedCategory = 'All';
  int _currentPage = 1;
  static const int _itemsPerPage = 3;
  late Future<List<SponsoredExperience>> _sponsoredFuture;
  late final ScrollController _scrollController;
  bool _isTopBarCollapsed = false;

  late final AnimationController _sunMoonRayController;
  late final AnimationController _stormController;

  bool _isStormyDemo = false;

  Timer? _clockTimer;
  String _tempCelsius = '27°C';
  String _weatherDesc = 'Clear Sky';
  IconData _weatherIcon = Icons.wb_sunny_rounded;

  late final PageController _sponsoredPageController;
  Timer? _sponsoredAutoTimer;
  int _currentSponsoredPage = 0;
  int _sponsoredCampaignCount = 5;

  final TextEditingController _smartSearchController = TextEditingController();
  bool _isSmartSearching = false;
  List<ExperienceItem> _dynamicExperiences = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _refreshSponsored();
    _fetchDynamicExperiences();

    _sponsoredPageController = PageController(viewportFraction: 0.93);
    _sponsoredAutoTimer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (_sponsoredPageController.hasClients && _sponsoredCampaignCount > 0) {
        _currentSponsoredPage = (_currentSponsoredPage + 1) % _sponsoredCampaignCount;
        _sponsoredPageController.animateToPage(
          _currentSponsoredPage,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    _sunMoonRayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _stormController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fetchWeather();

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptLocationOnAppOpen();
    });
  }

  Future<void> _fetchDynamicExperiences() async {
    if (!mounted) return;
    try {
      final itinState = ref.read(itineraryProvider);
      final targetDest = itinState.destination.isNotEmpty ? itinState.destination : 'Mumbai';
      final coords = GeocodingService.resolveCoordinatesForCity(targetDest);

      final recs = await ItineraryApiService.fetchRecommendations(
        destination: targetDest,
        startLocation: targetDest,
        startLat: coords.latitude,
        startLon: coords.longitude,
        budget: 5000,
        durationHours: 6,
        travelerCount: 2,
        travelerType: 'Couple',
        interests: const ['Culture', 'Food', 'Nature'],
        topN: 30,
      );
      if (recs.isNotEmpty && mounted) {
        setState(() {
          _dynamicExperiences = recs.map((r) => ExperienceItem(
            id: r.experienceId,
            title: r.name,
            category: r.category,
            subCategory: r.subCategory?.isNotEmpty == true ? r.subCategory! : r.category,
            rating: r.rating ?? 4.5,
            reviewCount: r.reviewCount ?? 120,
            durationHours: r.durationHours > 0 ? r.durationHours : 2.0,
            distanceKm: r.distanceKm ?? 3.5,
            priceInr: r.price,
            location: r.location.isNotEmpty ? r.location : '$targetDest, India',
            description: r.reason.isNotEmpty ? r.reason : 'Authentic local experience in $targetDest',
            imageUrl: r.imageUrl?.isNotEmpty == true ? r.imageUrl! : r.image,
            isSaved: false,
            isSoldOut: false,
            matchReasons: r.reason.isNotEmpty ? [r.reason] : const [],
          )).toList();
        });
        return;
      }
    } catch (e) {
      debugPrint('[HomeScreen] Dynamic experiences fetch error: $e');
    }
    if (mounted) {
      setState(() {
        _dynamicExperiences = LocalLensMockData.featuredExperiences;
      });
    }
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > 30 && !_isTopBarCollapsed) {
      setState(() {
        _isTopBarCollapsed = true;
      });
    } else if (offset <= 30 && _isTopBarCollapsed) {
      setState(() {
        _isTopBarCollapsed = false;
      });
    }
  }

  @override
  void dispose() {
    _sponsoredAutoTimer?.cancel();
    _sponsoredPageController.dispose();
    _clockTimer?.cancel();
    _smartSearchController.dispose();
    _sunMoonRayController.dispose();
    _stormController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Groq-powered natural language prompt smart search handler
  Future<void> _handleSmartSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSmartSearching = true;
    });

    try {
      final itinState = ref.read(itineraryProvider);
      final lat = itinState.latitude;
      final lon = itinState.longitude;
      final city = itinState.destination.isNotEmpty ? itinState.destination : 'Mumbai';

      final res = await ItineraryApiService.smartSearch(
        query: query,
        userLat: lat,
        userLon: lon,
        city: city,
      );

      final parsedIntent = (res['parsed_intent'] as Map<String, dynamic>?) ?? {};
      final recs = (res['recommendations'] as List<RecommendationModel>?) ?? [];

      if (!mounted) return;

      if (recs.isNotEmpty) {
        // Hydrate itinerary provider with Groq parsed intent + ML recommendations
        ref.read(itineraryProvider.notifier).applySmartSearchResult(
              parsedIntent: parsedIntent,
              recommendations: recs,
            );

        final vibe = parsedIntent['vibe_summary']?.toString() ?? 'Experiences tailored to your journey!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vibe,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Redirect directly to the recommendation swipe page
        context.push(AppRoutes.recommendationSwipe);
      } else {
        // Fallback: switch to Explore tab if no specific items matched
        setState(() {
          _currentTabIndex = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            content: const Text('Browsing spots matching your search...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[HomeScreen] Smart Search failed: $e');
      if (mounted) {
        setState(() {
          _currentTabIndex = 1;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSmartSearching = false;
        });
      }
    }
  }

  Future<void> _fetchWeather() async {
    // Read API key from .env (WEATHER_API_KEY) with hardcoded fallback
    final apiKey = dotenv.isInitialized
        ? (dotenv.env['WEATHER_API_KEY'] ?? '9fb8d155eeb443116f6d35e81215a121')
        : '9fb8d155eeb443116f6d35e81215a121';
    try {
      final loc = await LocationService.getCurrentResolvedLocation();
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${loc.latitude}&lon=${loc.longitude}&appid=$apiKey&units=metric',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final main = data['main'];
        final weatherList = data['weather'] as List?;
        if (main != null && weatherList != null && weatherList.isNotEmpty) {
          final temp = (main['temp'] as num).round();
          final item = weatherList.first;
          final desc = (item['description'] as String?) ?? 'Clear Sky';
          final iconCode = (item['icon'] as String?) ?? '01d';

          if (mounted) {
            setState(() {
              _tempCelsius = '$temp°C';
              _weatherDesc = _capitalizeWords(desc);
              _weatherIcon = _getOWMWeatherIcon(iconCode);
            });
          }
          return;
        }
      }
    } catch (_) {}

    // Fallback to time-based smart estimation if offline/timeout
    final hour = DateTime.now().hour;
    if (mounted) {
      setState(() {
        if (hour >= 5 && hour < 8) {
          _tempCelsius = '24°C';
          _weatherDesc = 'Sunrise / Cool';
          _weatherIcon = Icons.wb_twilight_rounded;
        } else if (hour >= 8 && hour < 17) {
          _tempCelsius = '29°C';
          _weatherDesc = 'Clear & Sunny';
          _weatherIcon = Icons.wb_sunny_rounded;
        } else if (hour >= 17 && hour < 20) {
          _tempCelsius = '26°C';
          _weatherDesc = 'Golden Sunset';
          _weatherIcon = Icons.wb_sunny_outlined;
        } else {
          _tempCelsius = '22°C';
          _weatherDesc = 'Clear Night';
          _weatherIcon = Icons.nights_stay_rounded;
        }
      });
    }
  }

  IconData _getOWMWeatherIcon(String iconCode) {
    if (iconCode.startsWith('01')) return Icons.wb_sunny_rounded;
    if (iconCode.startsWith('02') || iconCode.startsWith('03')) return Icons.wb_cloudy_rounded;
    if (iconCode.startsWith('04')) return Icons.cloud_rounded;
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Icons.water_drop_rounded;
    if (iconCode.startsWith('11')) return Icons.thunderstorm_rounded;
    if (iconCode.startsWith('13')) return Icons.ac_unit_rounded;
    if (iconCode.startsWith('50')) return Icons.dehaze_rounded;
    return Icons.wb_sunny_rounded;
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _refreshSponsored() {
    setState(() {
      _sponsoredFuture = SponsorService.fetchActiveSponsoredExperiences();
    });
  }

  Future<void> _promptLocationOnAppOpen() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      await LocationService.requestLocationPermission(context);
    }
  }

  Widget _buildUserAvatar(UserProfile? userProfile) {
    final photoUrl = userProfile?.photoUrl;
    final hasRealPhoto = photoUrl != null && photoUrl.trim().isNotEmpty && photoUrl.startsWith('http');
    // Real Gmail / Google User Profile Image format
    const googleGmailFallbackUrl = 'https://lh3.googleusercontent.com/a/ACg8ocIq8x4d16wV9P-b2Wk?s=96-c';
    final avatarUrl = hasRealPhoto ? photoUrl : googleGmailFallbackUrl;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isStormyDemo = !_isStormyDemo;
          if (_isStormyDemo) {
            _tempCelsius = '17°C';
            _weatherDesc = 'Heavy Rain & Thunderstorm';
            _weatherIcon = Icons.thunderstorm_rounded;
            _stormController.repeat();
            ref.read(itineraryProvider.notifier).setWeatherCondition('Heavy Thunderstorm');
          } else {
            _fetchWeather();
            _stormController.stop();
            ref.read(itineraryProvider.notifier).setWeatherCondition('Live');
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _isStormyDemo ? const Color(0xFF00E5FF) : const Color(0xFF111827).withValues(alpha: 0.25),
            width: _isStormyDemo ? 2.8 : 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isStormyDemo
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.65)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: _isStormyDemo ? 12 : 6,
              spreadRadius: _isStormyDemo ? 1.5 : 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.white,
                child: Center(
                  child: Text(
                    (userProfile?.displayName.isNotEmpty == true)
                        ? userProfile!.displayName[0].toUpperCase()
                        : 'G',
                    style: const TextStyle(
                      color: Color(0xFFFF1744),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showWeatherConditionsModal(BuildContext context) {
    final scenarios = [
      {
        'key': 'Clear / Sunny',
        'label': 'Clear & Sunny',
        'icon': Icons.wb_sunny_rounded,
        'temp': '28°C',
        'desc': 'Ideal for outdoor sightseeing, beaches, walking tours',
        'color': const Color(0xFFE65100),
        'bg': const Color(0xFFFFF3E0),
        'rain': '0.0 mm',
        'wind': '12 km/h',
        'humidity': '45%',
      },
      {
        'key': 'Partly Cloudy',
        'label': 'Partly Cloudy',
        'icon': Icons.cloud_queue_rounded,
        'temp': '24°C',
        'desc': 'Great touring conditions with pleasant breeze',
        'color': const Color(0xFF0288D1),
        'bg': const Color(0xFFE1F5FE),
        'rain': '0.2 mm',
        'wind': '15 km/h',
        'humidity': '60%',
      },
      {
        'key': 'Rain Showers',
        'label': 'Rain Showers',
        'icon': Icons.grain_rounded,
        'temp': '21°C',
        'desc': 'Intermittent rain; indoor cultural stops recommended',
        'color': const Color(0xFF1565C0),
        'bg': const Color(0xFFE3F2FD),
        'rain': '8.0 mm',
        'wind': '22 km/h',
        'humidity': '85%',
      },
      {
        'key': 'Heavy Thunderstorm',
        'label': 'Heavy Thunderstorm',
        'icon': Icons.thunderstorm_rounded,
        'temp': '18°C',
        'desc': 'Heavy rain & lightning; outdoor coastal spots unsafe',
        'color': const Color(0xFF4527A0),
        'bg': const Color(0xFFEDE7F6),
        'rain': '28.0 mm',
        'wind': '38 km/h',
        'humidity': '95%',
      },
      {
        'key': 'Extreme Heat',
        'label': 'Extreme Heat',
        'icon': Icons.whatshot_rounded,
        'temp': '38°C',
        'desc': 'High thermal stress; visit indoors during midday peak',
        'color': const Color(0xFFC62828),
        'bg': const Color(0xFFFFEBEE),
        'rain': '0.0 mm',
        'wind': '8 km/h',
        'humidity': '30%',
      },
      {
        'key': 'Hazy / Foggy',
        'label': 'Hazy / Foggy',
        'icon': Icons.blur_on_rounded,
        'temp': '22°C',
        'desc': 'Reduced visibility; close-range experiences advised',
        'color': const Color(0xFF455A64),
        'bg': const Color(0xFFECEFF1),
        'rain': '0.0 mm',
        'wind': '6 km/h',
        'humidity': '75%',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LocalLensColors.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.wb_sunny_rounded, color: LocalLensColors.primaryTeal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Weather & Simulation Center',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: LocalLensColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Plan and adapt your itinerary according to weather',
                            style: TextStyle(
                              fontSize: 12,
                              color: LocalLensColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable scenarios list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Live Current Weather Highlight Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isStormyDemo
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFFFFB300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _weatherIcon,
                            size: 36,
                            color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFFF57F17),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade700,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'CURRENT LIVE',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _tempCelsius,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: _isStormyDemo ? Colors.white : const Color(0xFF212121),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _weatherDesc,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _isStormyDemo ? const Color(0xFF94A3B8) : const Color(0xFF5D4037),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              ref.read(itineraryProvider.notifier).setWeatherCondition('Live');
                              setState(() {
                                _isStormyDemo = false;
                                _fetchWeather();
                                _stormController.stop();
                              });
                              Navigator.pop(ctx);
                              context.push(AppRoutes.travelerCreateItinerary);
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                            label: const Text('Plan Trip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              foregroundColor: _isStormyDemo ? Colors.white : LocalLensColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section header
                    const Text(
                      'All Weather Conditions & Itinerary Adaptation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: LocalLensColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap any condition to plan an itinerary automatically optimized for indoor shelter or open-air adventures:',
                      style: TextStyle(
                        fontSize: 12,
                        color: LocalLensColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Weather scenario cards
                    ...scenarios.map((scenario) => _buildWeatherScenarioCard(ctx, scenario)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherScenarioCard(BuildContext ctx, Map<String, dynamic> scenario) {
    final key = scenario['key'] as String;
    final label = scenario['label'] as String;
    final icon = scenario['icon'] as IconData;
    final temp = scenario['temp'] as String;
    final desc = scenario['desc'] as String;
    final color = scenario['color'] as Color;
    final bg = scenario['bg'] as Color;
    final rain = scenario['rain'] as String;
    final wind = scenario['wind'] as String;
    final humidity = scenario['humidity'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          temp,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: LocalLensColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 11, color: LocalLensColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildWeatherMetricBadge(Icons.water_drop_outlined, 'Rain: $rain'),
              const SizedBox(width: 12),
              _buildWeatherMetricBadge(Icons.air_rounded, 'Wind: $wind'),
              const SizedBox(width: 12),
              _buildWeatherMetricBadge(Icons.opacity_rounded, 'Hum: $humidity'),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  ref.read(createItineraryProvider.notifier).setWeatherCondition(key);
                  Navigator.pop(ctx);
                  context.push(AppRoutes.travelerCreateItinerary);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Plan Itinerary', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetricBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: LocalLensColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: LocalLensColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: _isStormyDemo ? const Color(0xFF0F172A) : const Color(0xFFFFFAF7),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 🌸 Inverted Atithi Devo Bhava Logo Watermark Background in Dark/Stormy Mode
            Positioned(
              right: -35,
              top: 120,
              width: 440,
              height: 440,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: _isStormyDemo ? 0.22 : 0.26,
                  child: ColorFiltered(
                    colorFilter: _isStormyDemo
                        ? const ColorFilter.matrix(<double>[
                            -1, 0, 0, 0, 255,
                             0,-1, 0, 0, 255,
                             0, 0,-1, 0, 255,
                             0, 0, 0, 1,   0,
                          ])
                        : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                    child: Image.asset(
                      'assets/images/atithi_devo_bhava_logo.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -55,
              bottom: 80,
              width: 380,
              height: 380,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: _isStormyDemo ? 0.16 : 0.20,
                  child: ColorFiltered(
                    colorFilter: _isStormyDemo
                        ? const ColorFilter.matrix(<double>[
                            -1, 0, 0, 0, 255,
                             0,-1, 0, 0, 255,
                             0, 0,-1, 0, 255,
                             0, 0, 0, 1,   0,
                          ])
                        : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                    child: Image.asset(
                      'assets/images/atithi_devo_bhava_logo.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),

            // 🌧️ Zomato-Style Realistic Raindrops Stream (BACKGROUND LAYER ONLY - BEHIND ALL CARDS & CONTENT)
            if (_isStormyDemo)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _stormController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ZomatoScreenWideRainAndLightningPainter(
                          stormProgress: _stormController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Main App Content Tabs
            IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildHomeTab(context),
                ExploreScreen(isStormy: _isStormyDemo),
                MyItineraryScreen(isStormy: _isStormyDemo),
                SavedScreen(isStormy: _isStormyDemo),
                ProfileScreen(isStormy: _isStormyDemo),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActiveRideFloatingBar(isStormy: _isStormyDemo),
            LocalLensBottomNav(
              currentIndex: _currentTabIndex,
              isStormy: _isStormyDemo,
              onTap: (index) {
                setState(() {
                  _currentTabIndex = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = ref.watch(currentUserProfileProvider);

    final allExperiences = _dynamicExperiences.isNotEmpty
        ? _dynamicExperiences
        : LocalLensMockData.featuredExperiences;

    // Filter Experiences based on Selected Category Chip
    final filteredExperiences = _selectedCategory == 'All'
        ? allExperiences
        : allExperiences.where((exp) {
            final catLower = _selectedCategory.toLowerCase();
            return exp.category.toLowerCase() == catLower ||
                exp.subCategory.toLowerCase().contains(catLower);
          }).toList();

    // Calculate Pagination
    final totalPages = (filteredExperiences.isEmpty)
        ? 1
        : (filteredExperiences.length / _itemsPerPage).ceil();

    final safeCurrentPage = _currentPage.clamp(1, totalPages);
    final startIndex = (safeCurrentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < filteredExperiences.length)
        ? startIndex + _itemsPerPage
        : filteredExperiences.length;

    final pagedExperiences = (filteredExperiences.isNotEmpty && startIndex < filteredExperiences.length)
        ? filteredExperiences.sublist(startIndex, endIndex)
        : <ExperienceItem>[];

    return AppBackgroundWrapper(
      isDark: _isStormyDemo,
      child: SafeArea(
        bottom: false,
        child: Column(
        children: [
          // 🍑 1. SOFT PEACH TOP BAR (#F7E2D5) OR DARK STORMY BAR (#1E293B) WITH REALTIME WEATHER & ANIMATION
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isStormyDemo ? const Color(0xFF1E293B) : const Color(0xFFF7E2D5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(_isTopBarCollapsed ? 24 : 44),
                bottomRight: Radius.circular(_isTopBarCollapsed ? 24 : 44),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isStormyDemo ? 0.35 : 0.09),
                  blurRadius: _isTopBarCollapsed ? 12 : 24,
                  offset: Offset(0, _isTopBarCollapsed ? 4 : 10),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: Listenable.merge([_sunMoonRayController, _stormController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: SunriseSunsetArcPainter(
                    animationProgress: _sunMoonRayController.value,
                    isStormy: _isStormyDemo,
                    stormProgress: _stormController.value,
                  ),
                  child: child,
                );
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  _isTopBarCollapsed ? 14 : 32,
                  22,
                  _isTopBarCollapsed ? 16 : 42,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User Greeting & Smart Weather/Time Row (Where To Next Removed)
                    AnimatedCrossFade(
                      firstChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // App Brand Header (LocalLens)
                                    Text(
                                      'LocalLens',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: _isStormyDemo ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
                                        letterSpacing: -0.8,
                                        height: 1.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _isStormyDemo
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : const Color(0xFF111827).withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.notifications_none_rounded,
                                        color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFF111827),
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        context.push(AppRoutes.notifications);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // REAL GMAIL AVATAR IMAGE
                                  _buildUserAvatar(userProfile),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 58),
                        ],
                      ),
                      secondChild: const SizedBox.shrink(),
                      crossFadeState: _isTopBarCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),

                    // ONLY INPUT FIELD REMAINS VISIBLE ON TOP BAR WHEN USER SCROLLS DOWN
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      decoration: BoxDecoration(
                        color: _isStormyDemo ? const Color(0xFF334155) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(_isTopBarCollapsed ? 18 : 28),
                          bottomRight: Radius.circular(_isTopBarCollapsed ? 18 : 28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: _isStormyDemo ? 0.3 : 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _smartSearchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (query) => _handleSmartSearch(query),
                        style: TextStyle(
                          fontSize: 14,
                          color: _isStormyDemo ? Colors.white : const Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask AI: e.g. 2 hr, ₹1500, couple, sunset & street food...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: _isStormyDemo ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: _isSmartSearching
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.auto_awesome_rounded,
                                  color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                  size: 22,
                                ),
                          suffixIcon: GestureDetector(
                            onTap: () => _handleSmartSearch(_smartSearchController.text),
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _isStormyDemo
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF2563EB).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                size: 18,
                              ),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                        ),
                      ),
                  ),
                ],
              ),
            ),
          ),
        ),

          // 📜 2. SCROLLABLE BODY CONTENT (STICKY TOPBAR COLLAPSES TO SHOW ONLY SEARCH BAR)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshSponsored(),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LocalLensDimensions.paddingScreen,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔮 FAMOUS LOCATION BACKGROUND "PLAN WITH LOCAL AI" HERO BANNER
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: double.infinity,
                        height: 295,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _isStormyDemo
                                  ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                                  : const Color(0xFFFF1744).withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              // 1. Background Famous Place Image with Atmospheric Blending
                              Positioned.fill(
                                child: ColorFiltered(
                                  colorFilter: _isStormyDemo
                                      ? ColorFilter.mode(const Color(0xFF0F172A).withValues(alpha: 0.18), BlendMode.darken)
                                      : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?q=80&w=1200&auto=format&fit=crop',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFC62828),
                                      child: const Center(
                                        child: Icon(Icons.landscape_rounded, color: Colors.white54, size: 60),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 2. Dark Gradient Overlay Transition
                              Positioned.fill(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isStormyDemo
                                          ? [
                                              Colors.black.withValues(alpha: 0.4),
                                              const Color(0xFF0F172A).withValues(alpha: 0.75),
                                              const Color(0xFF1E293B).withValues(alpha: 0.95),
                                            ]
                                          : [
                                              Colors.black.withValues(alpha: 0.3),
                                              const Color(0xFFB71C1C).withValues(alpha: 0.55),
                                              Colors.black.withValues(alpha: 0.88),
                                            ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),

                              // 3. Top Badges: User Location, Realtime Weather & AI Spotlight Badge
                              Positioned(
                                top: 16,
                                left: 16,
                                right: 16,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            // Location Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.55),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.location_on_rounded, color: Color(0xFFFF5252), size: 14),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Panvel, Maharashtra',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // ☀️ REALTIME TEMPERATURE & WEATHER BADGE
                                            GestureDetector(
                                              onTap: () => _showWeatherConditionsModal(context),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.55),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _isStormyDemo
                                                        ? const Color(0xFF38BDF8).withValues(alpha: 0.8)
                                                        : const Color(0xFFFFD54F).withValues(alpha: 0.6),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      _weatherIcon,
                                                      color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFFFFD54F),
                                                      size: 11,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '$_tempCelsius • $_weatherDesc',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _isStormyDemo
                                            ? const Color(0xFF0288D1).withValues(alpha: 0.9)
                                            : const Color(0xFFFF1744).withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                                          SizedBox(width: 4),
                                          Text(
                                            'AI SPOTLIGHT',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 4. Header Text and Button Positioned at Bottom
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Explore Panvel & Nearby Hidden Gems',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        height: 1.2,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tailored local itinerary crafted specifically for your area',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () {
                                        context.push(AppRoutes.travelerCreateItinerary);
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 350),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: _isStormyDemo
                                                    ? [const Color(0xFF0288D1), const Color(0xFF01579B)]
                                                    : [const Color(0xFFFF1744), const Color(0xFFD50000)],
                                              ),
                                              borderRadius: BorderRadius.circular(30),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.2),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Plan with Local AI',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                SizedBox(width: 6),
                                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SPONSORED EXPERIENCES SECTION (FEATURED SPOTLIGHT HEADER + INTERACTIVE CAROUSEL)
                      FutureBuilder<List<SponsoredExperience>>(
                        future: _sponsoredFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: _isStormyDemo ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                                border: Border.all(color: _isStormyDemo ? const Color(0xFF334155) : LocalLensColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFFFF1744),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Loading spotlight deals...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isStormyDemo ? Colors.white : const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final campaigns = snapshot.data ?? [];
                          if (campaigns.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          _sponsoredCampaignCount = campaigns.length;
                          return StatefulBuilder(
                            builder: (context, setCarouselState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // BOLD PROMINENT FEATURED SPOTLIGHT HEADER
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.star_rounded,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'FEATURED SPOTLIGHT',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w900,
                                                        color: Colors.white,
                                                        letterSpacing: 0.8,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _isStormyDemo ? const Color(0xFF1E3A8A) : const Color(0xFFFEF3C7),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'SPONSORED',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    color: _isStormyDemo ? const Color(0xFF93C5FD) : const Color(0xFF92400E),
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Promoted local deals & partner experiences',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _isStormyDemo ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // INTERACTIVE CAROUSEL (AUTO-SCROLL + SWIPE CONTROL)
                                  SizedBox(
                                    height: 270,
                                    child: PageView.builder(
                                      controller: _sponsoredPageController,
                                      itemCount: campaigns.length,
                                      onPageChanged: (index) {
                                        setCarouselState(() {
                                          _currentSponsoredPage = index;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        final camp = campaigns[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: GestureDetector(
                                            onTap: () {
                                              _showSponsoredDetailModal(context, camp);
                                            },
                                            child: _buildSponsoredCard(context, camp, isDark),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // CAROUSEL DOT INDICATORS
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(campaigns.length, (dotIndex) {
                                        final isSelected = _currentSponsoredPage == dotIndex;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          width: isSelected ? 22 : 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (_isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFFFF1744))
                                                : (_isStormyDemo ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              );
                            },
                          );
                        },
                      ),

                      // Category Chips (Interactive Category Filtering)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip('All'),
                            _buildCategoryChip('Food'),
                            _buildCategoryChip('Heritage'),
                            _buildCategoryChip('Culture'),
                            _buildCategoryChip('Nature'),
                            _buildCategoryChip('Crafts'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. EXPLORE NEARBY GEMS (FILTERED & PAGINATED)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCategory == 'All'
                                    ? 'Explore Nearby Gems'
                                    : 'Explore $_selectedCategory Gems',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                  color: _isStormyDemo ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Showing ${pagedExperiences.length} of ${filteredExperiences.length} authentic local spots',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _isStormyDemo ? const Color(0xFF94A3B8) : const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentTabIndex = 1; // Go to Explore Tab
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isStormyDemo
                                    ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                                    : const Color(0xFFFF1744).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isStormyDemo
                                      ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                                      : const Color(0xFFFF1744).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'See all',
                                    style: TextStyle(
                                      color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFFFF1744),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFFFF1744),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // EMPTY STATE IF NO EXPERIENCES FOR CATEGORY
                      if (pagedExperiences.isEmpty) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _isStormyDemo ? const Color(0xFF1E293B) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isStormyDemo ? const Color(0xFF334155) : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: _isStormyDemo ? const Color(0xFF64748B) : Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No $_selectedCategory gems found nearby.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _isStormyDemo ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try selecting another category chip above.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isStormyDemo ? const Color(0xFF94A3B8) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // VERTICAL LIST OF FILTERED & PAGINATED NEARBY GEMS
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagedExperiences.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final exp = pagedExperiences[index];
                            return ExperienceCard(
                              title: exp.title,
                              imageUrl: exp.imageUrl,
                              rating: exp.rating,
                              category: exp.category,
                              priceInr: exp.priceInr,
                              location: exp.location,
                              distanceKm: exp.distanceKm,
                              durationHours: exp.durationHours,
                              onTap: () => context.push(
                                AppRoutes.experienceDetails,
                                extra: {
                                  'title': exp.title,
                                  'imageUrl': exp.imageUrl,
                                  'rating': exp.rating,
                                  'category': exp.category,
                                  'priceInr': exp.priceInr,
                                  'location': exp.location,
                                  'distanceKm': exp.distanceKm,
                                  'durationHours': exp.durationHours,
                                  'description': 'Discover authentic regional heritage, culinary delights, and curated local spots in Panvel with expert host guidance.',
                                  'shopName': 'LocalLens Verified Host',
                                },
                              ),
                              onBookRideTap: () {
                                showRideBookingBottomSheet(
                                  context: context,
                                  ref: ref,
                                  destinationTitle: exp.title,
                                  destinationLocation: exp.location,
                                  distanceKm: exp.distanceKm,
                                );
                              },
                              width: double.infinity,
                              isStormy: _isStormyDemo,
                            );
                          },
                        ),
                      ],

                      // 🔢 PAGINATION CONTROLS BAR
                      if (totalPages > 1) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Previous Page Button
                            IconButton(
                              onPressed: safeCurrentPage > 1
                                  ? () {
                                      setState(() {
                                        _currentPage = safeCurrentPage - 1;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_left_rounded),
                              color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFFFF1744),
                              disabledColor: _isStormyDemo ? const Color(0xFF334155) : Colors.grey.shade300,
                            ),
                            const SizedBox(width: 8),

                            // Page Number Buttons
                            ...List.generate(totalPages, (index) {
                              final pageNum = index + 1;
                              final isSelected = pageNum == safeCurrentPage;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _currentPage = pageNum;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isStormyDemo
                                        ? (isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B))
                                        : (isSelected ? const Color(0xFFFF1744) : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isStormyDemo
                                          ? (isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155))
                                          : (isSelected ? const Color(0xFFFF1744) : Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Text(
                                    '$pageNum',
                                    style: TextStyle(
                                      color: _isStormyDemo
                                          ? (isSelected ? const Color(0xFF0F172A) : Colors.white)
                                          : (isSelected ? Colors.white : const Color(0xFF111827)),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(width: 8),

                            // Next Page Button
                            IconButton(
                              onPressed: safeCurrentPage < totalPages
                                  ? () {
                                      setState(() {
                                        _currentPage = safeCurrentPage + 1;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_right_rounded),
                              color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFFFF1744),
                              disabledColor: _isStormyDemo ? const Color(0xFF334155) : Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Section: Your Trip (DIV HEADER WITH BOLD WEIGHTED BLACK FONTS)
                      Text(
                        'Your trip',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: _isStormyDemo ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentTabIndex = 2; // Go to Trips
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isStormyDemo ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                            boxShadow: LocalLensDimensions.softCardShadow,
                            border: Border.all(
                              color: _isStormyDemo ? const Color(0xFF334155) : LocalLensColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _isStormyDemo
                                      ? Color(0xFF38BDF8).withValues(alpha: 0.15)
                                      : Color(0xFFFF1744).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.route_rounded,
                                  color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFFFF1744),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Panvel Local Discovery',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: _isStormyDemo ? Colors.white : const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '4 experiences • 6h 30m • ₹1,450',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _isStormyDemo ? const Color(0xFF94A3B8) : const Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFF111827),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isStormyDemo
              ? (isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B))
              : (isSelected ? const Color(0xFFE53935) : Colors.white),
          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
          border: Border.all(
            color: _isStormyDemo
                ? (isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155))
                : (isSelected ? const Color(0xFFE53935) : LocalLensColors.border),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _isStormyDemo
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                        : const Color(0xFFE53935).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _isStormyDemo
                ? (isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1))
                : (isSelected ? Colors.white : LocalLensColors.textPrimary),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSponsoredCard(BuildContext context, SponsoredExperience camp, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: _isStormyDemo ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isStormyDemo
              ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
              : const Color(0xFFFBBF24).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isStormyDemo
                ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                : const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: ColorFiltered(
                  colorFilter: _isStormyDemo
                      ? ColorFilter.mode(const Color(0xFF0F172A).withValues(alpha: 0.18), BlendMode.darken)
                      : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: Image.network(
                    camp.imageUrl,
                    height: 115,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 115,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_rounded, size: 32, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        camp.badge.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00875A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    camp.offer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  camp.listingName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _isStormyDemo ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Sponsored by: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isStormyDemo ? const Color(0xFF94A3B8) : Colors.black54,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        camp.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFF00875A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '${camp.rating} (${camp.reviewsCount})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isStormyDemo ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        camp.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: _isStormyDemo ? const Color(0xFF94A3B8) : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${camp.offerPrice.toInt()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _isStormyDemo ? const Color(0xFF38BDF8) : const Color(0xFF00875A),
                      ),
                    ),
                    Text(
                      '/person',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isStormyDemo ? const Color(0xFF64748B) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${camp.originalPrice.toInt()}/person',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: _isStormyDemo ? const Color(0xFF64748B) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSponsoredDetailModal(BuildContext context, SponsoredExperience camp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = _isStormyDemo;
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF111827);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? const Color(0xFF334155) : LocalLensColors.border),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            'FEATURED PARTNER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD97706),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  camp.listingName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Promoted by ${camp.shopName} • ${camp.location}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_rounded, color: Color(0xFFD97706)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              camp.offer,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Special LocalLens partner deal',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exclusive Price',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '₹${camp.offerPrice.toInt()}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFFFF1744),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${camp.originalPrice.toInt()}',
                              style: TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                                color: isDark ? const Color(0xFF64748B) : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.touch_app_rounded, size: 18),
                      label: const Text('Explore Deal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF0284C7) : const Color(0xFFFF1744),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.experienceDetails, extra: camp.toJson());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🎨 Custom Painter for Red/Cyan Beam Sweep + Water Droplet Splash on Right Edge
class RedSweepWaterSplashPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final bool isStormy;

  RedSweepWaterSplashPainter({
    required this.progress,
    this.borderRadius = 16.0,
    this.isStormy = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Base subtle card border stroke
    final baseBorderPaint = Paint()
      ..color = isStormy ? const Color(0xFF334155) : const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect, baseBorderPaint);

    // 2. Beam Flow sweeping from Left to Right (0.0 -> 1.0)
    final sweepProgress = progress; // 0.0 to 1.0
    final startX = -size.width + (sweepProgress * size.width * 2.4);
    final endX = startX + size.width * 0.7;

    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: isStormy
            ? [
                const Color(0x0000E5FF),
                const Color(0xFF00E5FF),
                const Color(0xFF38BDF8),
                const Color(0x0000E5FF),
              ]
            : [
                const Color(0x00FF1744),
                const Color(0xFFFF1744),
                const Color(0xFFFF5252),
                const Color(0x00FF1744),
              ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromLTRB(startX, 0, endX, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(rrect, sweepPaint);

    // 3. Water Droplets Splash at the end (Right Edge)
    if (progress > 0.55) {
      final splashT = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
      final rightX = size.width - 2;
      final centerY = size.height / 2;

      // Expanding Water Ripple Ring 1 on Right Edge
      final ringRadius = 5.0 + (splashT * 26.0);
      final ringAlpha = (1.0 - splashT) * 0.8;
      final ringPaint = Paint()
        ..color = (isStormy ? const Color(0xFF38BDF8) : const Color(0xFF00E5FF)).withValues(alpha: ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(rightX, centerY), ringRadius, ringPaint);

      // Expanding Water Ripple Ring 2 (Outer Ocean Wave)
      final outerRingPaint = Paint()
        ..color = (isStormy ? const Color(0xFF0288D1) : const Color(0xFF00B0FF)).withValues(alpha: ringAlpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(rightX, centerY), ringRadius * 1.4, outerRingPaint);

      // Animated Water Droplet Particles bursting outwards on the Right Edge
      final droplets = [
        {'dx': 20.0, 'dy': -22.0, 'r': 4.5, 'color': const Color(0xFF00E5FF)},
        {'dx': 28.0, 'dy': -8.0,  'r': 5.5, 'color': const Color(0xFF00B0FF)},
        {'dx': 24.0, 'dy': 12.0,  'r': 4.0, 'color': isStormy ? const Color(0xFF38BDF8) : const Color(0xFFFF1744)},
        {'dx': 14.0, 'dy': 24.0,  'r': 5.0, 'color': const Color(0xFF00E5FF)},
        {'dx': 32.0, 'dy': 4.0,   'r': 3.5, 'color': const Color(0xFF0288D1)},
      ];

      for (final d in droplets) {
        final dx = d['dx'] as double;
        final dy = d['dy'] as double;
        final baseR = d['r'] as double;
        final color = d['color'] as Color;

        final px = rightX + (dx * splashT);
        final py = centerY + (dy * splashT);
        final radius = baseR * (1.0 - (splashT * 0.5));
        final alpha = (1.0 - splashT).clamp(0.0, 1.0);

        final dropPaint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), radius, dropPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RedSweepWaterSplashPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isStormy != isStormy;
  }
}

/// Custom Painter for Realtime Sunrise-to-Sunset Arc & Stormy Thunderstrike Mode
class SunriseSunsetArcPainter extends CustomPainter {
  final double animationProgress; // 0.0 to 1.0 ray pulse animation
  final bool isStormy;
  final double stormProgress; // 0.0 to 1.0 storm animation controller

  SunriseSunsetArcPainter({
    required this.animationProgress,
    this.isStormy = false,
    this.stormProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isStormy) {
      _paintStormyMode(canvas, size);
      return;
    }

    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final currentMinute = hour * 60 + minute;

    // Define celestial arc path across top bar (Balanced Arc Trajectory)
    final startPoint = Offset(6, size.height * 0.90);
    final endPoint = Offset(size.width - 6, size.height * 0.90);
    final controlPoint = Offset(size.width / 2, size.height * -0.10);

    final arcPath = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    // 1. Draw subtle dashed arc line
    final arcPaint = Paint()
      ..color = const Color(0xFF111827).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final pMetrics = arcPath.computeMetrics();
    for (final metric in pMetrics) {
      double distance = 0.0;
      const dashWidth = 7.0;
      const dashSpace = 5.0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extractPath, arcPaint);
        distance += dashWidth + dashSpace;
      }
    }

    // Daytime: 6:00 AM (360 mins) to 6:30 PM (1110 mins)
    final bool isDaytime = currentMinute >= 360 && currentMinute < 1110;

    double progress;
    if (isDaytime) {
      progress = (currentMinute - 360) / 750.0;
    } else {
      final nightMins = currentMinute >= 1110 ? currentMinute - 1110 : currentMinute + 330;
      progress = nightMins / 690.0;
    }
    progress = progress.clamp(0.0, 1.0);

    final t = progress;
    final bx = (1 - t) * (1 - t) * startPoint.dx + 2 * (1 - t) * t * controlPoint.dx + t * t * endPoint.dx;
    final by = (1 - t) * (1 - t) * startPoint.dy + 2 * (1 - t) * t * controlPoint.dy + t * t * endPoint.dy;
    final orbCenter = Offset(bx, by);

    if (isDaytime) {
      // ☀️ SUN ANIMATION (BALANCED ELEGANT SUN ORB & RAYS)
      final isSunriseOrSunset = hour >= 17 || hour <= 7;
      final sunColor = isSunriseOrSunset ? const Color(0xFFFF6D00) : const Color(0xFFFFAB00);

      // Sun Outer Glow
      final glowPaint = Paint()
        ..color = sunColor.withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(orbCenter, 24.0 + (animationProgress * 6.0), glowPaint);

      // Sun Body (Slightly Smaller & Balanced)
      final sunPaint = Paint()..color = sunColor;
      canvas.drawCircle(orbCenter, 16.0, sunPaint);

      // Pulsing Sun Rays
      final rayPaint = Paint()
        ..color = sunColor.withValues(alpha: 0.90)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      const numRays = 10;
      final rayLength = 10.0 + (animationProgress * 4.0);
      const baseRayDist = 19.5;

      for (int i = 0; i < numRays; i++) {
        final angle = (i * (2 * math.pi / numRays)) + (animationProgress * math.pi * 0.25);
        final startX = orbCenter.dx + math.cos(angle) * baseRayDist;
        final startY = orbCenter.dy + math.sin(angle) * baseRayDist;
        final endX = orbCenter.dx + math.cos(angle) * (baseRayDist + rayLength);
        final endY = orbCenter.dy + math.sin(angle) * (baseRayDist + rayLength);
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
      }
    } else {
      // 🌙 MOON & TWINKLING STARS ANIMATION (BALANCED MOON ORB)
      final moonGlowPaint = Paint()
        ..color = const Color(0xFF5C6BC0).withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(orbCenter, 22.0, moonGlowPaint);

      final moonPaint = Paint()..color = const Color(0xFF5C6BC0);
      canvas.drawCircle(orbCenter, 14.5, moonPaint);

      // Crescent Shadow cutout
      final shadowPaint = Paint()..color = const Color(0xFFF7E2D5);
      canvas.drawCircle(Offset(orbCenter.dx + 5.5, orbCenter.dy - 4.0), 12.0, shadowPaint);

      // Twinkling background stars
      final starPaint = Paint()..color = const Color(0xFF5C6BC0).withValues(alpha: 0.65 + (animationProgress * 0.35));
      final stars = [
        Offset(orbCenter.dx - 32, orbCenter.dy - 12),
        Offset(orbCenter.dx + 36, orbCenter.dy + 10),
        Offset(orbCenter.dx - 16, orbCenter.dy + 22),
      ];
      for (final star in stars) {
        canvas.drawCircle(star, 2.5 + (animationProgress * 1.0), starPaint);
      }
    }
  }

  void _paintStormyMode(Canvas canvas, Size size) {
    // 1. Dark Storm Arc Trajectory
    final startPoint = Offset(6, size.height * 0.90);
    final endPoint = Offset(size.width - 6, size.height * 0.90);
    final controlPoint = Offset(size.width / 2, size.height * -0.10);

    final arcPath = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    final stormArcPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final pMetrics = arcPath.computeMetrics();
    for (final metric in pMetrics) {
      double distance = 0.0;
      const dashWidth = 7.0;
      const dashSpace = 5.0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extractPath, stormArcPaint);
        distance += dashWidth + dashSpace;
      }
    }

    // 2. Rolling Dark Storm Clouds (Atmospheric Smooth Gradient Layer)
    final cloudPath1 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 32)
      ..quadraticBezierTo(size.width * 0.2, 50, size.width * 0.45, 26)
      ..quadraticBezierTo(size.width * 0.75, 5, size.width, 36)
      ..lineTo(size.width, 0)
      ..close();

    final cloudPath2 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 20)
      ..quadraticBezierTo(size.width * 0.35, 42, size.width * 0.65, 18)
      ..quadraticBezierTo(size.width * 0.85, 48, size.width, 24)
      ..lineTo(size.width, 0)
      ..close();

    final cloudPaint1 = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    final cloudPaint2 = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawPath(cloudPath1, cloudPaint1);
    canvas.drawPath(cloudPath2, cloudPaint2);

    // 3. Falling Raindrops Animation (Continuous 60 FPS Smooth Flow)
    final rainPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.65)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const numDrops = 35;
    for (int i = 0; i < numDrops; i++) {
      final startX = (i * 23.0 + (i % 5) * 11.0) % size.width;
      final speedFactor = 1.0 + ((i % 3) * 0.35);
      final rawY = ((i * 19.0) + (stormProgress * size.height * 1.5 * speedFactor)) % (size.height + 40);
      final y = rawY - 20;

      canvas.drawLine(
        Offset(startX, y),
        Offset(startX - 5.0, y + 15.0),
        rainPaint,
      );
    }

    // 4. Compact Short-Height Thunderstrike & Lightning Flash (INSIDE TOP BAR ONLY)
    final isLightningStrike = (stormProgress >= 0.14 && stormProgress <= 0.30) ||
        (stormProgress >= 0.62 && stormProgress <= 0.78);

    if (isLightningStrike) {
      double strikeT;
      if (stormProgress <= 0.30) {
        strikeT = (stormProgress - 0.14) / 0.16;
      } else {
        strikeT = (stormProgress - 0.62) / 0.16;
      }

      // Short twin-pulse sky flash inside top bar only
      final double doubleFlashT = (math.sin(strikeT * math.pi * 2).abs()).clamp(0.0, 1.0);
      final flashOpacity = (doubleFlashT * 0.28).clamp(0.0, 0.28);
      final flashPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: flashOpacity);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);

      // Compact Short-Height Lightning Bolt Path (y = 4 -> y = 62 max inside top bar)
      final originX = size.width * (stormProgress <= 0.30 ? 0.65 : 0.32);
      final boltPath = Path()
        ..moveTo(originX, 4)
        ..lineTo(originX - 10, 20)
        ..lineTo(originX + 12, 34)
        ..lineTo(originX - 6,  48)
        ..lineTo(originX + 14, 62);

      final branchPath = Path()
        ..moveTo(originX + 12, 34)
        ..lineTo(originX + 28, 44)
        ..lineTo(originX + 22, 54);

      // High-Voltage Cyan Neon Glow
      final glowPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: (0.95 * doubleFlashT).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawPath(boltPath, glowPaint);
      canvas.drawPath(branchPath, glowPaint);

      // Core White Lightning Strike Bolt
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: doubleFlashT.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(boltPath, corePaint);
      canvas.drawPath(branchPath, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SunriseSunsetArcPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.isStormy != isStormy ||
        oldDelegate.stormProgress != stormProgress;
  }
}

/// 🌧️ Zomato-Style Realistic Screen-Wide Rain Custom Painter
class ZomatoScreenWideRainAndLightningPainter extends CustomPainter {
  final double stormProgress;

  ZomatoScreenWideRainAndLightningPainter({required this.stormProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // Multi-Layer Screen-Wide Raindrops Stream
    const numDrops = 65;
    const dxSlant = -6.0;

    for (int i = 0; i < numDrops; i++) {
      final seedX = (i * 37.0 + (i % 7) * 53.0) % size.width;
      final speedMult = 0.8 + ((i % 5) * 0.28);
      final rawY = ((i * 31.0) + (stormProgress * size.height * 1.8 * speedMult)) % (size.height + 60);
      final y = rawY - 30;
      final x = seedX + ((y / size.height) * dxSlant);

      final layer = i % 3;
      double dropLength;
      double strokeWidth;
      Color dropColor;

      if (layer == 0) {
        dropLength = 28.0;
        strokeWidth = 1.8;
        dropColor = const Color(0xFF00E5FF).withValues(alpha: 0.65);
      } else if (layer == 1) {
        dropLength = 20.0;
        strokeWidth = 1.4;
        dropColor = const Color(0xFF38BDF8).withValues(alpha: 0.42);
      } else {
        dropLength = 14.0;
        strokeWidth = 1.0;
        dropColor = const Color(0xFF0288D1).withValues(alpha: 0.28);
      }

      final dropPaint = Paint()
        ..color = dropColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + dxSlant, y + dropLength),
        dropPaint,
      );

      // Micro splash ring ripples on lower screen
      if (layer == 0 && (i % 4 == 0) && y > size.height * 0.45) {
        final splashAlpha = ((y - size.height * 0.45) / (size.height * 0.55)).clamp(0.0, 0.4);
        final splashPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: (0.4 - splashAlpha).clamp(0.0, 0.4))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y + dropLength), width: 8.0, height: 3.0),
          splashPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ZomatoScreenWideRainAndLightningPainter oldDelegate) {
    return oldDelegate.stormProgress != stormProgress;
  }
}
