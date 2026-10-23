// ==============================================================================
// LocalLens Web - Geocoding & City Coordinates Service
// Direct translation of traveler-app's geocoding_service.dart
// ==============================================================================

export interface GeoPoint {
  latitude: number;
  longitude: number;
}

export const CITY_COORDINATES: Record<string, GeoPoint> = {
  mumbai: { latitude: 19.0760, longitude: 72.8777 },
  'south mumbai': { latitude: 18.9220, longitude: 72.8347 },
  'navi mumbai': { latitude: 19.0330, longitude: 73.0297 },
  thane: { latitude: 19.2183, longitude: 72.9781 },
  pune: { latitude: 18.5204, longitude: 73.8567 },
  nashik: { latitude: 19.9975, longitude: 73.7898 },
  delhi: { latitude: 28.6139, longitude: 77.2090 },
  'new delhi': { latitude: 28.6139, longitude: 77.2090 },
  jaipur: { latitude: 26.9124, longitude: 75.7873 },
  udaipur: { latitude: 24.5854, longitude: 73.7125 },
  jodhpur: { latitude: 26.2389, longitude: 73.0243 },
  jaisalmer: { latitude: 26.9157, longitude: 70.9083 },
  goa: { latitude: 15.2993, longitude: 74.1240 },
  'north goa': { latitude: 15.4909, longitude: 73.8278 },
  'south goa': { latitude: 15.2736, longitude: 73.9582 },
  bangalore: { latitude: 12.9716, longitude: 77.5946 },
  bengaluru: { latitude: 12.9716, longitude: 77.5946 },
  hyderabad: { latitude: 17.3850, longitude: 78.4867 },
  kolkata: { latitude: 22.5726, longitude: 88.3639 },
  chennai: { latitude: 13.0827, longitude: 80.2707 },
  ahmedabad: { latitude: 23.0225, longitude: 72.5714 },
  agra: { latitude: 27.1767, longitude: 78.0081 },
  varanasi: { latitude: 25.3176, longitude: 82.9739 },
  kochi: { latitude: 9.9312, longitude: 76.2673 },
  munnar: { latitude: 10.0889, longitude: 77.0595 },
  alleppey: { latitude: 9.4981, longitude: 76.3388 },
  shimla: { latitude: 31.1048, longitude: 77.1734 },
  manali: { latitude: 32.2432, longitude: 77.1892 },
  rishikesh: { latitude: 30.0869, longitude: 78.2676 },
  lonavala: { latitude: 18.7557, longitude: 73.4091 },
  alibaug: { latitude: 18.6414, longitude: 72.8722 },
  panvel: { latitude: 18.9894, longitude: 73.1175 },
};

const reverseCache = new Map<string, string>();

export const GeocodingService = {
  resolveCoordinatesForCity(cityName: string): GeoPoint {
    const clean = cityName.trim().toLowerCase();
    if (!clean) return { latitude: 19.0760, longitude: 72.8777 };

    if (CITY_COORDINATES[clean]) {
      return CITY_COORDINATES[clean];
    }

    for (const [key, value] of Object.entries(CITY_COORDINATES)) {
      if (clean.includes(key) || key.includes(clean)) {
        return value;
      }
    }

    return { latitude: 19.0760, longitude: 72.8777 };
  },

  async getLocationName(lat: number, lon: number, fallbackCity = 'Mumbai, Maharashtra'): Promise<string> {
    if (!lat || !lon) return fallbackCity;

    const key = `${lat.toFixed(3)},${lon.toFixed(3)}`;
    if (reverseCache.has(key)) return reverseCache.get(key)!;

    // Local area boundary check
    if (lat >= 18.95 && lat <= 19.03 && lon >= 73.08 && lon <= 73.15) {
      reverseCache.set(key, 'Panvel, Navi Mumbai');
      return 'Panvel, Navi Mumbai';
    }
    if (lat >= 19.04 && lat <= 19.08 && lon >= 72.82 && lon <= 72.88) {
      reverseCache.set(key, 'Bandra, Mumbai');
      return 'Bandra, Mumbai';
    }

    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json&addressdetails=1`,
        { headers: { 'User-Agent': 'LocalLensWeb/1.0' } }
      );
      if (res.ok) {
        const data = await res.json();
        const addr = data.address;
        if (addr) {
          const area = addr.suburb || addr.neighbourhood || addr.quarter || addr.city_district;
          const city = addr.city || addr.town || addr.county || 'Mumbai';
          const name = area ? `${area}, ${city}` : city;
          reverseCache.set(key, name);
          return name;
        }
      }
    } catch {}

    return fallbackCity;
  },
};
