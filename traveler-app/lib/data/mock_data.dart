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
    ExperienceItem(
      id: 'exp-1',
      title: 'Sunset by the Coast',
      category: 'Nature',
      subCategory: 'Coastal Viewpoint',
      rating: 4.8,
      reviewCount: 2300,
      durationHours: 2.5,
      distanceKm: 12.0,
      priceInr: 899.0,
      location: 'Panvel Coastline, Maharashtra',
      description:
          'Enjoy a beautiful sunset with authentic local food, coastal viewpoints, and a rich cultural experience curated by local guides.',
      imageUrl: 'assets/images/54506.png',
      matchReasons: [
        'Matches your interest in scenic views',
        'Fits your 3-hour afternoon window',
        'Within your set budget range',
      ],
    ),
    ExperienceItem(
      id: 'exp-2',
      title: 'Local Food Trail',
      category: 'Food',
      subCategory: 'Culinary Walking Tour',
      rating: 4.8,
      reviewCount: 2100,
      durationHours: 2.0,
      distanceKm: 8.0,
      priceInr: 399.0,
      location: 'Old Town Heritage Market',
      description:
          'Taste 6+ iconic authentic street delicacies with a veteran foodie and uncover culinary traditions.',
      imageUrl: 'assets/images/54511.png',
      matchReasons: [
        'Top-rated culinary experience',
        'Direct local provider connection',
      ],
    ),
    ExperienceItem(
      id: 'exp-3',
      title: 'Heritage Walk',
      category: 'Culture',
      subCategory: 'Historic Walking Tour',
      rating: 4.6,
      reviewCount: 1800,
      durationHours: 3.0,
      distanceKm: 12.0,
      priceInr: 450.0,
      location: 'Karnala Foothills, Panvel',
      description:
          'Discover 16th-century fortress history, ancient stone steps, and hidden stories of the region.',
      imageUrl: 'assets/images/54506.png',
      matchReasons: [
        'Matches your cultural interest',
        'Moderate walking intensity',
      ],
    ),
    ExperienceItem(
      id: 'exp-4',
      title: 'Beachside Cafe',
      category: 'Food',
      subCategory: 'Artisanal Cafe',
      rating: 4.7,
      reviewCount: 1200,
      durationHours: 1.5,
      distanceKm: 5.0,
      priceInr: 350.0,
      location: 'Alibaug Coast Road',
      description:
          'Relax by the waves with artisanal cold brews and coastal snacks in a tranquil open-air atmosphere.',
      imageUrl: 'assets/images/54511.png',
    ),
    ExperienceItem(
      id: 'exp-5',
      title: 'Waterfall Trek',
      category: 'Adventure',
      subCategory: 'Guided Nature Hike',
      rating: 4.9,
      reviewCount: 950,
      durationHours: 4.0,
      distanceKm: 22.0,
      priceInr: 499.0,
      location: 'Gadeshwar Reservoir Trail',
      description:
          'Trek through lush green valleys, stream crossings, and dip into natural freshwater plunge pools.',
      imageUrl: 'assets/images/54506.png',
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
