import 'package:flutter/material.dart';

/// Experience Model
class ExperienceItem {
  final String id;
  final String title;
  final String category;
  final String subCategory;
  final double rating;
  final int reviewCount;
  final double durationHours;
  final double distanceKm;
  final double priceInr;
  final String location;
  final String description;
  final String imageUrl;
  final bool isSaved;
  final bool isSoldOut;
  final List<String> matchReasons;

  const ExperienceItem({
    required this.id,
    required this.title,
    required this.category,
    required this.subCategory,
    required this.rating,
    required this.reviewCount,
    required this.durationHours,
    required this.distanceKm,
    required this.priceInr,
    required this.location,
    required this.description,
    required this.imageUrl,
    this.isSaved = false,
    this.isSoldOut = false,
    this.matchReasons = const [],
  });
}

/// Category item model
class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Travel Group Model
class TravelGroupOption {
  final String id;
  final String title;
  final String subtitle;
  final String avatarKey;
  final IconData icon;

  const TravelGroupOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.avatarKey,
    required this.icon,
  });
}

/// Itinerary Stop Model
class ItineraryStop {
  final String id;
  final String time;
  final String title;
  final String category;
  final double durationHours;
  final double priceInr;
  final double distanceKm;
  final bool isCompleted;
  final bool isActive;
  final String iconType;

  const ItineraryStop({
    required this.id,
    required this.time,
    required this.title,
    required this.category,
    required this.durationHours,
    required this.priceInr,
    required this.distanceKm,
    this.isCompleted = false,
    this.isActive = false,
    required this.iconType,
  });
}

/// Notification Item Model
class LocalLensNotification {
  final String id;
  final String title;
  final String timeAgo;
  final String type; // ride, weather, gem, itinerary, promo
  final IconData icon;
  final Color iconBgColor;

  const LocalLensNotification({
    required this.id,
    required this.title,
    required this.timeAgo,
    required this.type,
    required this.icon,
    required this.iconBgColor,
  });
}

/// Central Mock Data Source
class LocalLensMockData {
  static const List<CategoryItem> categories = [
    CategoryItem(
      id: 'food',
      name: 'Food',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF6B4A),
    ),
    CategoryItem(
      id: 'culture',
      name: 'Culture',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF0E8388),
    ),
    CategoryItem(
      id: 'adventure',
      name: 'Adventure',
      icon: Icons.explore_rounded,
      color: Color(0xFFF59E0B),
    ),
    CategoryItem(
      id: 'nature',
      name: 'Nature',
      icon: Icons.park_rounded,
      color: Color(0xFF10B981),
    ),
  ];

  static const List<TravelGroupOption> groupOptions = [
    TravelGroupOption(
      id: 'solo',
      title: 'Solo',
      subtitle: '1 traveler',
      avatarKey: 'solo',
      icon: Icons.person_rounded,
    ),
    TravelGroupOption(
      id: 'couple',
      title: 'Couple',
      subtitle: '2 travelers',
      avatarKey: 'couple',
      icon: Icons.favorite_rounded,
    ),
    TravelGroupOption(
      id: 'friends',
      title: 'Friends',
      subtitle: '3-5 travelers',
      avatarKey: 'friends',
      icon: Icons.group_rounded,
    ),
    TravelGroupOption(
      id: 'family',
      title: 'Family',
      subtitle: 'Kids + Adults',
      avatarKey: 'family',
      icon: Icons.family_restroom_rounded,
    ),
    TravelGroupOption(
      id: 'business',
      title: 'Business',
      subtitle: 'Work trip',
      avatarKey: 'business',
      icon: Icons.work_rounded,
    ),
    TravelGroupOption(
      id: 'senior',
      title: 'Senior',
      subtitle: 'Leisure & comfort',
      avatarKey: 'senior',
      icon: Icons.elderly_rounded,
    ),
  ];

  static const List<String> interestsList = [
    'Food',
    'Culture',
    'Adventure',
    'Nature',
    'Heritage',
    'Beach',
    'Shopping',
    'Nightlife',
    'Photography',
  ];

  static const List<ExperienceItem> featuredExperiences = [
    // --- FOOD EXPERIENCES (from CSV dataset) ---
    ExperienceItem(
      id: 'NAVI-007',
      title: 'Utsav Chowk Street Food Hub',
      category: 'Food',
      subCategory: 'Street Food Trail',
      rating: 4.8,
      reviewCount: 520,
      durationHours: 1.5,
      distanceKm: 3.8,
      priceInr: 150.0,
      location: 'Kharghar, Navi Mumbai',
      description:
          'A landmark circle in Kharghar famous for its Greek-style architecture and wide spread of street food delicacies.',
      imageUrl: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800&q=80',
      matchReasons: [
        'Top-rated street food hub',
        'Within 4 km of Panvel',
        'Budget friendly authentic eats',
      ],
    ),
    ExperienceItem(
      id: 'NAVI-010',
      title: 'Ghati Misal Kharghar',
      category: 'Food',
      subCategory: 'Maharashtrian Cuisine',
      rating: 4.9,
      reviewCount: 680,
      durationHours: 1.0,
      distanceKm: 4.2,
      priceInr: 100.0,
      location: 'Kharghar, Navi Mumbai',
      description:
          'Authentic, freshly made fiery Maharashtrian misal pav with farsan and freshly baked pavs.',
      imageUrl: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800&q=80',
      matchReasons: [
        'Iconic regional delicacy',
        'Local favorite morning spot',
      ],
    ),
    ExperienceItem(
      id: 'KONKAN004',
      title: 'Ratnagiri Fish Market & Seafood Trail',
      category: 'Food',
      subCategory: 'Coastal Seafood Feast',
      rating: 4.8,
      reviewCount: 430,
      durationHours: 2.5,
      distanceKm: 5.5,
      priceInr: 550.0,
      location: 'Coastal Harbour, Maharashtra',
      description:
          'Morning harbour fish auction followed by a tasting trail of local Malvani & Konkani surmai thalis and bombil fry.',
      imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&q=80',
    ),
    ExperienceItem(
      id: 'NAVI-014',
      title: 'Cafe Monza Kharghar',
      category: 'Food',
      subCategory: 'Artisanal Cafe',
      rating: 4.7,
      reviewCount: 310,
      durationHours: 1.5,
      distanceKm: 4.5,
      priceInr: 600.0,
      location: 'Kharghar, Navi Mumbai',
      description:
          'Laid-back highway-side cafe serving specialty brews, fresh pizzas and artisanal brunch snacks.',
      imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&q=80',
    ),

    // --- CULTURE EXPERIENCES (from CSV dataset) ---
    ExperienceItem(
      id: 'KONKAN012',
      title: 'Prachin Konkan Rural Crafts & Museum',
      category: 'Culture',
      subCategory: 'Living Heritage Museum',
      rating: 4.8,
      reviewCount: 750,
      durationHours: 2.0,
      distanceKm: 3.5,
      priceInr: 60.0,
      location: 'Ganpatipule, Maharashtra',
      description:
          'An open-air museum recreating old Konkani village life with life-size dioramas of rural crafts, tools and ancient traditions.',
      imageUrl: 'https://images.unsplash.com/photo-1565008447742-97f6f38c985c?w=800&q=80',
      matchReasons: [
        'Rich regional history',
        'Hands-on artisan demonstrations',
      ],
    ),
    ExperienceItem(
      id: 'KONKAN005',
      title: 'Alphonso Mango Orchard Farming Walk',
      category: 'Culture',
      subCategory: 'Agri-Heritage Tour',
      rating: 4.9,
      reviewCount: 610,
      durationHours: 2.5,
      distanceKm: 6.0,
      priceInr: 350.0,
      location: 'Ratnagiri Orchards, Maharashtra',
      description:
          'Guided walk through famous Hapus (Alphonso) mango orchards with generational farmers explaining traditional cultivation.',
      imageUrl: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800&q=80',
    ),
    ExperienceItem(
      id: 'KONKAN024',
      title: 'Guhagar Coconut & Betel-nut Grove Trail',
      category: 'Culture',
      subCategory: 'Plantation Walk',
      rating: 4.7,
      reviewCount: 290,
      durationHours: 1.5,
      distanceKm: 4.8,
      priceInr: 200.0,
      location: 'Guhagar Groves, Maharashtra',
      description:
          'A tranquil guided walk through dense coconut and areca-nut plantations with insight into coastal rural life.',
      imageUrl: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800&q=80',
    ),

    // --- ADVENTURE EXPERIENCES (from CSV dataset) ---
    ExperienceItem(
      id: 'NAVI-006',
      title: 'Kharghar Valley Golf & Range',
      category: 'Adventure',
      subCategory: 'Outdoor Sport & Range',
      rating: 4.8,
      reviewCount: 420,
      durationHours: 3.0,
      distanceKm: 4.2,
      priceInr: 1200.0,
      location: 'Kharghar Valley, Navi Mumbai',
      description:
          'Sprawling valley golf course and driving range against scenic Sahyadri hills with professional coaches.',
      imageUrl: 'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=800&q=80',
      matchReasons: [
        'Panoramic valley views',
        'Top outdoor adventure in Navi Mumbai',
      ],
    ),
    ExperienceItem(
      id: 'NAVI-011',
      title: 'Kharghar Hills Sunset Nature Hike',
      category: 'Adventure',
      subCategory: 'Guided Hill Hike',
      rating: 4.9,
      reviewCount: 880,
      durationHours: 2.5,
      distanceKm: 3.5,
      priceInr: 250.0,
      location: 'Kharghar Hills, Navi Mumbai',
      description:
          'Lush scenic trail offering sweeping panoramic views of the creek, CIDCO golf course and western horizon sunset.',
      imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800&q=80',
    ),
    ExperienceItem(
      id: 'KONKAN040',
      title: 'Coastal Jet Ski & Water Sports',
      category: 'Adventure',
      subCategory: 'Marine Adventure',
      rating: 4.8,
      reviewCount: 540,
      durationHours: 2.0,
      distanceKm: 7.5,
      priceInr: 999.0,
      location: 'Coastal Beach, Maharashtra',
      description:
          'High-octane jet skiing, banana boat rides and bumper rides with certified lifeguards and safety gear.',
      imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&q=80',
    ),

    // --- NATURE EXPERIENCES (from CSV dataset) ---
    ExperienceItem(
      id: 'NAVI-001',
      title: 'Pandavkada Waterfalls & Valley',
      category: 'Nature',
      subCategory: 'Waterfall & Valley',
      rating: 4.8,
      reviewCount: 1420,
      durationHours: 2.5,
      distanceKm: 3.2,
      priceInr: 50.0,
      location: 'Kharghar, Navi Mumbai',
      description:
          'A majestic 107-metre high waterfall situated in the Kharghar hills, surrounded by dense greenery and rock formations.',
      imageUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=800&q=80',
      matchReasons: [
        'Close proximity (3.2 km)',
        'Stunning seasonal cascade views',
      ],
    ),
    ExperienceItem(
      id: 'NAVI-004',
      title: 'Central Park Botanical Gardens',
      category: 'Nature',
      subCategory: 'Urban Eco Park',
      rating: 4.7,
      reviewCount: 980,
      durationHours: 2.0,
      distanceKm: 4.0,
      priceInr: 20.0,
      location: 'Kharghar, Navi Mumbai',
      description:
          'One of Asia’s largest landscaped urban parks featuring botanical trails, amphitheatre, water bodies and open lawns.',
      imageUrl: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=800&q=80',
    ),
    ExperienceItem(
      id: 'KONKAN034',
      title: 'Unhavare Geothermal Hot Springs',
      category: 'Nature',
      subCategory: 'Natural Springs',
      rating: 4.9,
      reviewCount: 390,
      durationHours: 2.0,
      distanceKm: 6.5,
      priceInr: 100.0,
      location: 'Unhavare, Maharashtra',
      description:
          'Natural hot sulphur water springs with therapeutic mineral waters nestled in a scenic Konkan river valley.',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
    ),
  ];

  static const List<ItineraryStop> dayItineraryStops = [
    ItineraryStop(
      id: 'stop-1',
      time: '09:00',
      title: 'Breakfast at Local Cafe',
      category: 'Food',
      durationHours: 1.0,
      priceInr: 250,
      distanceKm: 2.0,
      isCompleted: true,
      iconType: 'cafe',
    ),
    ItineraryStop(
      id: 'stop-2',
      time: '11:30',
      title: 'Heritage Walk',
      category: 'Culture',
      durationHours: 2.0,
      priceInr: 450,
      distanceKm: 4.5,
      isCompleted: true,
      iconType: 'walk',
    ),
    ItineraryStop(
      id: 'stop-3',
      time: '13:30',
      title: 'Explore Local Market',
      category: 'Shopping',
      durationHours: 1.5,
      priceInr: 350,
      distanceKm: 1.8,
      isCompleted: true,
      iconType: 'market',
    ),
    ItineraryStop(
      id: 'stop-4',
      time: '15:30',
      title: 'Local Food Experience',
      category: 'Food',
      durationHours: 1.5,
      priceInr: 400,
      distanceKm: 3.2,
      isActive: true,
      iconType: 'food',
    ),
    ItineraryStop(
      id: 'stop-5',
      time: '17:30',
      title: 'Sunset Point',
      category: 'Nature',
      durationHours: 1.5,
      priceInr: 0,
      distanceKm: 5.0,
      iconType: 'sunset',
    ),
    ItineraryStop(
      id: 'stop-6',
      time: '19:30',
      title: 'Return to Hotel',
      category: 'Transit',
      durationHours: 0.5,
      priceInr: 120,
      distanceKm: 6.0,
      iconType: 'hotel',
    ),
  ];

  static const List<LocalLensNotification> notifications = [
    LocalLensNotification(
      id: 'notif-1',
      title: 'Your ride arrives in 5 min.',
      timeAgo: '2m ago',
      type: 'ride',
      icon: Icons.directions_car_rounded,
      iconBgColor: Color(0xFF0E8388),
    ),
    LocalLensNotification(
      id: 'notif-2',
      title: 'Rain expected in 30 min. We adjusted your itinerary.',
      timeAgo: '15m ago',
      type: 'weather',
      icon: Icons.cloud_queue_rounded,
      iconBgColor: Color(0xFF3B82F6),
    ),
    LocalLensNotification(
      id: 'notif-3',
      title: 'We found a hidden gem nearby: Artisanal Bakery.',
      timeAgo: '1h ago',
      type: 'gem',
      icon: Icons.auto_awesome_rounded,
      iconBgColor: Color(0xFFF59E0B),
    ),
    LocalLensNotification(
      id: 'notif-4',
      title: 'Your itinerary has been updated.',
      timeAgo: '2h ago',
      type: 'itinerary',
      icon: Icons.route_rounded,
      iconBgColor: Color(0xFF10B981),
    ),
    LocalLensNotification(
      id: 'notif-5',
      title: 'Special offer: 15% off on coastal experiences!',
      timeAgo: 'Yesterday',
      type: 'promo',
      icon: Icons.local_offer_rounded,
      iconBgColor: Color(0xFFFF6B4A),
    ),
  ];
}

typedef MockData = LocalLensMockData;

