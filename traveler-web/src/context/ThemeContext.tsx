'use client';

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { WeatherData, WeatherService, WEATHER_SCENARIOS } from '@/lib/weather';

interface ThemeContextType {
  isStormy: boolean;
  weather: WeatherData;
  toggleStormDemo: () => void;
  applyWeatherScenario: (key: string) => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [isStormy, setIsStormy] = useState(false);
  const [weather, setWeather] = useState<WeatherData>({
    tempCelsius: '27°C',
    description: 'Clear Sky',
    condition: 'Clear',
    humidity: '55%',
    windSpeed: '12 km/h',
    rainMm: '0.0 mm',
    isStormy: false,
    iconName: 'Sun',
  });

  useEffect(() => {
    WeatherService.fetchLiveWeather(19.076, 72.8777).then((w) => {
      setWeather(w);
      if (w.isStormy) setIsStormy(true);
    });
  }, []);

  function toggleStormDemo() {
    setIsStormy((prev) => {
      const next = !prev;
      if (next) {
        setWeather({
          tempCelsius: '17°C',
          description: 'Heavy Rain & Thunderstorm',
          condition: 'Thunderstorm',
          humidity: '94%',
          windSpeed: '38 km/h',
          rainMm: '18.4 mm',
          isStormy: true,
          iconName: 'CloudRain',
        });
      } else {
        WeatherService.fetchLiveWeather(19.076, 72.8777).then(setWeather);
      }
      return next;
    });
  }

  function applyWeatherScenario(key: string) {
    const sc = WEATHER_SCENARIOS.find((s) => s.key === key) || WEATHER_SCENARIOS[0];
    setIsStormy(sc.isStormy);
    setWeather({
      tempCelsius: sc.temp,
      description: sc.desc,
      condition: sc.label,
      humidity: sc.humidity,
      windSpeed: sc.wind,
      rainMm: sc.rain,
      isStormy: sc.isStormy,
      iconName: sc.icon,
    });
  }

  return (
    <ThemeContext.Provider value={{ isStormy, weather, toggleStormDemo, applyWeatherScenario }}>
      <div className={isStormy ? 'dark' : ''}>{children}</div>
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) throw new Error('useTheme must be used within a ThemeProvider');
  return context;
}
