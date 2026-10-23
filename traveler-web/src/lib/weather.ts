// ==============================================================================
// LocalLens Web - Weather & Simulation Service
// ==============================================================================

export interface WeatherData {
  tempCelsius: string;
  description: string;
  condition: string;
  humidity: string;
  windSpeed: string;
  rainMm: string;
  isStormy: boolean;
  iconName: string;
}

export const WEATHER_SCENARIOS = [
  {
    key: 'Clear / Sunny',
    label: 'Clear & Sunny',
    temp: '28°C',
    desc: 'Ideal for outdoor sightseeing, beaches, walking tours',
    isStormy: false,
    rain: '0.0 mm',
    wind: '12 km/h',
    humidity: '45%',
    icon: 'Sun',
  },
  {
    key: 'Heavy Rain / Storm',
    label: 'Heavy Rain & Thunderstorm',
    temp: '17°C',
    desc: 'Heavy monsoon downpour! Auto-prioritize indoor & sheltered stops',
    isStormy: true,
    rain: '18.4 mm',
    wind: '38 km/h',
    humidity: '94%',
    icon: 'CloudRain',
  },
  {
    key: 'Golden Sunset / Breeze',
    label: 'Golden Hour Sunset',
    temp: '24°C',
    desc: 'Soft golden lighting perfect for photography, coastal drives & viewpoints',
    isStormy: false,
    rain: '0.0 mm',
    wind: '14 km/h',
    humidity: '58%',
    icon: 'Sunset',
  },
  {
    key: 'Overcast / Mild',
    label: 'Pleasant & Overcast',
    temp: '22°C',
    desc: 'Cool cloud cover, comfortable walking weather with zero scorching heat',
    isStormy: false,
    rain: '0.2 mm',
    wind: '10 km/h',
    humidity: '68%',
    icon: 'Cloud',
  },
];

const DEFAULT_WEATHER_KEY = '9fb8d155eeb443116f6d35e81215a121';

export const WeatherService = {
  async fetchLiveWeather(lat: number, lon: number): Promise<WeatherData> {
    const key = process.env.NEXT_PUBLIC_WEATHER_API_KEY || DEFAULT_WEATHER_KEY;
    try {
      const res = await fetch(
        `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${key}&units=metric`
      );
      if (res.ok) {
        const data = await res.json();
        const temp = Math.round(data.main?.temp ?? 27);
        const desc = data.weather?.[0]?.description ?? 'Clear Sky';
        const mainCond = data.weather?.[0]?.main ?? 'Clear';
        const isStormy = mainCond.toLowerCase().includes('rain') || mainCond.toLowerCase().includes('storm');

        return {
          tempCelsius: `${temp}°C`,
          description: capitalize(desc),
          condition: mainCond,
          humidity: `${data.main?.humidity ?? 60}%`,
          windSpeed: `${Math.round((data.wind?.speed ?? 3.5) * 3.6)} km/h`,
          rainMm: `${data.rain?.['1h'] ?? 0} mm`,
          isStormy,
          iconName: isStormy ? 'CloudRain' : 'Sun',
        };
      }
    } catch {}

    return {
      tempCelsius: '27°C',
      description: 'Clear Sky',
      condition: 'Clear',
      humidity: '55%',
      windSpeed: '12 km/h',
      rainMm: '0 mm',
      isStormy: false,
      iconName: 'Sun',
    };
  },
};

function capitalize(str: string): string {
  return str
    .split(' ')
    .map((w) => (w.length > 0 ? w[0].toUpperCase() + w.substring(1) : ''))
    .join(' ');
}
