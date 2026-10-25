'use client';

import React, { useEffect, useRef, useState, useCallback } from 'react';
import L from 'leaflet';
import { Layers, MapPin, AlertCircle } from 'lucide-react';

export interface MapMarkerPoint {
  id: string;
  name: string;
  category?: string;
  latitude: number;
  longitude: number;
  isDriver?: boolean;
  isPickup?: boolean;
  isDrop?: boolean;
  orderNumber?: number;
}

interface InteractiveMapProps {
  markers?: MapMarkerPoint[];
  center?: [number, number];
  zoom?: number;
  showPolyline?: boolean;
  className?: string;
}

declare global {
  interface Window {
    google?: any;
    gm_authFailure?: () => void;
  }
}

function createMarkerSvg(
  label: string,
  bgColor: string = '#E85028',
  textColor: string = '#FFFFFF',
  isEmoji: boolean = false
): string {
  const size = 36;
  const radius = 15;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
    <defs>
      <filter id="shadow" x="-30%" y="-30%" width="160%" height="160%">
        <feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="rgba(0,0,0,0.35)"/>
      </filter>
    </defs>
    <circle cx="18" cy="18" r="${radius}" fill="${bgColor}" stroke="#FFFFFF" stroke-width="2.5" filter="url(#shadow)"/>
    <text x="18" y="${isEmoji ? 22 : 22.5}" font-family="system-ui, -apple-system, sans-serif" font-size="${isEmoji ? 15 : 13}" font-weight="800" fill="${textColor}" text-anchor="middle" dominant-baseline="middle">${label}</text>
  </svg>`;
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
}

export function InteractiveMap({
  markers = [],
  center,
  zoom = 13,
  showPolyline = true,
  className = 'h-72 w-full rounded-2xl overflow-hidden',
}: InteractiveMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const leafletMapRef = useRef<L.Map | null>(null);
  const googleMapRef = useRef<any>(null);
  const googleMarkersRef = useRef<any[]>([]);
  const googlePolylineRef = useRef<any>(null);
  const activeInfoWindowRef = useRef<any>(null);

  const [activeProvider, setActiveProvider] = useState<'google' | 'osm'>('google');
  const [googleStatus, setGoogleStatus] = useState<'idle' | 'loading' | 'ready' | 'failed'>('idle');
  const [authNotice, setAuthNotice] = useState<string | null>(null);

  const googleApiKey =
    process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY ||
    'AIzaSyCjkIl2fmZxKKLCn3wjMSnkn3NFroWBRZQ';

  const validMarkers = markers.filter(
    (m) => typeof m.latitude === 'number' && typeof m.longitude === 'number' && !isNaN(m.latitude) && !isNaN(m.longitude)
  );

  const effectiveCenter: [number, number] =
    center && center[0] && center[1]
      ? center
      : validMarkers.length > 0
      ? [validMarkers[0].latitude, validMarkers[0].longitude]
      : [20.5937, 78.9629];

  // Gracefully catch Google Maps authentication failure without throwing uncaught exceptions
  useEffect(() => {
    if (typeof window === 'undefined') return;

    const originalGmAuthFailure = window.gm_authFailure;
    window.gm_authFailure = () => {
      console.warn(
        '[LocalLens] Google Maps auth failure detected. Switching gracefully to OpenStreetMap engine.'
      );
      setGoogleStatus('failed');
      setAuthNotice('Google Maps API key not activated. Switched to OpenStreetMap.');
      setActiveProvider('osm');
      if (typeof originalGmAuthFailure === 'function') {
        try {
          originalGmAuthFailure();
        } catch {
          // ignore
        }
      }
    };

    return () => {
      window.gm_authFailure = originalGmAuthFailure;
    };
  }, []);

  // Initialize and update Google Maps
  const initGoogleMap = useCallback(() => {
    if (!containerRef.current || !window.google?.maps || activeProvider !== 'google') return;

    try {
      if (!googleMapRef.current) {
        const map = new window.google.maps.Map(containerRef.current, {
          center: { lat: effectiveCenter[0], lng: effectiveCenter[1] },
          zoom,
          mapTypeId: window.google.maps.MapTypeId.ROADMAP,
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: true,
          zoomControl: true,
          gestureHandling: 'cooperative',
          styles: [
            {
              featureType: 'poi',
              elementType: 'labels',
              stylers: [{ visibility: 'on' }],
            },
            {
              featureType: 'transit',
              elementType: 'labels',
              stylers: [{ visibility: 'on' }],
            },
          ],
        });
        googleMapRef.current = map;
      } else {
        googleMapRef.current.setCenter({ lat: effectiveCenter[0], lng: effectiveCenter[1] });
        googleMapRef.current.setZoom(zoom);
      }

      const map = googleMapRef.current;

      // Clear existing Google markers & polyline
      googleMarkersRef.current.forEach((m) => m.setMap(null));
      googleMarkersRef.current = [];

      if (googlePolylineRef.current) {
        googlePolylineRef.current.setMap(null);
        googlePolylineRef.current = null;
      }

      if (activeInfoWindowRef.current) {
        activeInfoWindowRef.current.close();
      }

      const bounds = new window.google.maps.LatLngBounds();
      const pathCoordinates: any[] = [];

      validMarkers.forEach((m) => {
        const position = { lat: m.latitude, lng: m.longitude };
        bounds.extend(position);
        pathCoordinates.push(position);

        let iconUrl = '';
        if (m.isDriver) {
          iconUrl = createMarkerSvg('🚗', '#E85028', '#FFFFFF', true);
        } else if (m.isPickup) {
          iconUrl = createMarkerSvg('P', '#5A7363', '#FFFFFF', false);
        } else if (m.isDrop) {
          iconUrl = createMarkerSvg('D', '#BA1A1A', '#FFFFFF', false);
        } else if (m.orderNumber != null) {
          iconUrl = createMarkerSvg(String(m.orderNumber), '#E85028', '#FFFFFF', false);
        } else {
          iconUrl = createMarkerSvg('📍', '#1A1A1A', '#FFFFFF', true);
        }

        const marker = new window.google.maps.Marker({
          position,
          map,
          title: m.name,
          icon: {
            url: iconUrl,
            scaledSize: new window.google.maps.Size(36, 36),
            anchor: new window.google.maps.Point(18, 18),
          },
        });

        const infoWindow = new window.google.maps.InfoWindow({
          content: `
            <div style="font-family: inherit; padding: 4px 6px; color: #1A1A1A;">
              <div style="font-weight: 800; font-size: 13px; line-height: 1.3;">${m.name}</div>
              ${m.category ? `<div style="font-size: 11px; color: #71717A; margin-top: 2px;">${m.category}</div>` : ''}
              ${m.orderNumber ? `<div style="font-size: 10px; font-weight: 700; color: #E85028; margin-top: 4px;">Stop #${m.orderNumber}</div>` : ''}
            </div>
          `,
        });

        marker.addListener('click', () => {
          if (activeInfoWindowRef.current) {
            activeInfoWindowRef.current.close();
          }
          infoWindow.open(map, marker);
          activeInfoWindowRef.current = infoWindow;
        });

        googleMarkersRef.current.push(marker);
      });

      // Draw polyline connecting stops
      if (showPolyline && pathCoordinates.length > 1) {
        const polyline = new window.google.maps.Polyline({
          path: pathCoordinates,
          geodesic: true,
          strokeColor: '#E85028',
          strokeOpacity: 0.85,
          strokeWeight: 4,
          map,
        });
        googlePolylineRef.current = polyline;

        map.fitBounds(bounds, { top: 40, right: 40, bottom: 40, left: 40 });
      } else if (pathCoordinates.length === 1) {
        map.setCenter(pathCoordinates[0]);
        map.setZoom(15);
      }

      setGoogleStatus('ready');
    } catch (err) {
      console.warn('[LocalLens] Error rendering Google Maps, switching to OSM fallback:', err);
      setGoogleStatus('failed');
      setActiveProvider('osm');
    }
  }, [effectiveCenter, zoom, validMarkers, showPolyline, activeProvider]);

  // Load Google Maps SDK
  useEffect(() => {
    if (activeProvider !== 'google') return;

    if (window.google?.maps) {
      initGoogleMap();
      return;
    }

    setGoogleStatus('loading');
    const scriptId = 'locallens-google-maps-script';
    const existing = document.getElementById(scriptId) as HTMLScriptElement | null;
    if (existing) {
      existing.addEventListener('load', () => initGoogleMap());
      return;
    }

    const script = document.createElement('script');
    script.id = scriptId;
    script.src = `https://maps.googleapis.com/maps/api/js?key=${googleApiKey}&libraries=places,geometry`;
    script.async = true;
    script.defer = true;

    script.onload = () => {
      setTimeout(() => {
        if (googleStatus !== 'failed') {
          initGoogleMap();
        }
      }, 200);
    };

    script.onerror = () => {
      console.warn('[LocalLens] Failed to load Google Maps script. Falling back to OpenStreetMap.');
      setGoogleStatus('failed');
      setActiveProvider('osm');
    };

    document.head.appendChild(script);
  }, [activeProvider, googleApiKey, googleStatus, initGoogleMap]);

  // Leaflet OpenStreetMap renderer (clean OSM tiles without Carto watermark)
  useEffect(() => {
    if (activeProvider !== 'osm') {
      if (leafletMapRef.current) {
        leafletMapRef.current.remove();
        leafletMapRef.current = null;
      }
      return;
    }

    if (!containerRef.current) return;

    // Reset container DOM if Google Map previously occupied it
    if (googleMapRef.current) {
      googleMapRef.current = null;
      containerRef.current.innerHTML = '';
    }

    if (!leafletMapRef.current) {
      const map = L.map(containerRef.current, {
        center: effectiveCenter,
        zoom,
        zoomControl: false,
      });

      // Clean OpenStreetMap standard tile layer (free of Carto API key restrictions)
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors',
        maxZoom: 19,
      }).addTo(map);

      L.control.zoom({ position: 'bottomright' }).addTo(map);
      leafletMapRef.current = map;
    } else {
      leafletMapRef.current.setView(effectiveCenter, zoom);
    }

    const map = leafletMapRef.current;

    // Clear previous layers except tile layer
    map.eachLayer((layer) => {
      if (layer instanceof L.Marker || layer instanceof L.Polyline) {
        map.removeLayer(layer);
      }
    });

    const latLngs: L.LatLngExpression[] = [];

    validMarkers.forEach((m) => {
      const latlng: [number, number] = [m.latitude, m.longitude];
      latLngs.push(latlng);

      let pinHtml = '';
      if (m.isDriver) {
        pinHtml = `<div style="background-color: #E85028; color: white; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 14px rgba(232,80,40,0.5); border: 2px solid white; font-size: 16px;">🚗</div>`;
      } else if (m.isPickup) {
        pinHtml = `<div style="background-color: #5A7363; color: white; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(90,115,99,0.4); border: 2px solid white; font-weight: bold; font-size: 11px;">P</div>`;
      } else if (m.isDrop) {
        pinHtml = `<div style="background-color: #BA1A1A; color: white; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(186,26,26,0.4); border: 2px solid white; font-weight: bold; font-size: 11px;">D</div>`;
      } else if (m.orderNumber != null) {
        pinHtml = `<div style="background-color: #E85028; color: white; width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 3px 10px rgba(232,80,40,0.4); border: 2px solid white; font-weight: 800; font-size: 12px;">${m.orderNumber}</div>`;
      } else {
        pinHtml = `<div style="background-color: #1A1A1A; color: white; width: 26px; height: 26px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 3px 8px rgba(0,0,0,0.3); border: 2px solid white; font-size: 11px;">📍</div>`;
      }

      const customIcon = L.divIcon({
        className: 'custom-leaflet-pin',
        html: pinHtml,
        iconSize: [32, 32],
        iconAnchor: [16, 16],
      });

      const marker = L.marker(latlng, { icon: customIcon }).addTo(map);
      marker.bindPopup(`<b>${m.name}</b><br/><span style="font-size:11px; color:#666;">${m.category || ''}</span>`);
    });

    if (showPolyline && latLngs.length > 1) {
      L.polyline(latLngs, {
        color: '#E85028',
        weight: 4,
        opacity: 0.85,
        dashArray: '6, 8',
      }).addTo(map);

      map.fitBounds(L.latLngBounds(latLngs), { padding: [40, 40] });
    }
  }, [activeProvider, effectiveCenter, zoom, validMarkers, showPolyline]);

  return (
    <div className={`relative ${className}`}>
      {/* Map Switcher Header Badge */}
      <div className="absolute top-3 right-3 z-20 flex items-center gap-1 bg-white/90 dark:bg-slate-900/90 backdrop-blur-md p-1 rounded-xl shadow-md border border-black/5 dark:border-white/10 text-[11px] font-semibold">
        <button
          type="button"
          onClick={() => {
            setActiveProvider('google');
            if (googleStatus === 'failed') setGoogleStatus('idle');
          }}
          className={`px-2.5 py-1 rounded-lg transition-all ${
            activeProvider === 'google'
              ? 'bg-primary text-white shadow-xs font-bold'
              : 'text-slate-600 dark:text-slate-300 hover:text-ink dark:hover:text-white'
          }`}
        >
          Google Maps
        </button>
        <button
          type="button"
          onClick={() => setActiveProvider('osm')}
          className={`px-2.5 py-1 rounded-lg transition-all ${
            activeProvider === 'osm'
              ? 'bg-primary text-white shadow-xs font-bold'
              : 'text-slate-600 dark:text-slate-300 hover:text-ink dark:hover:text-white'
          }`}
        >
          OpenStreetMap
        </button>
      </div>

      {/* Map Surface */}
      <div ref={containerRef} className="w-full h-full min-h-[260px]" />

      {/* Loading overlay for Google Maps */}
      {activeProvider === 'google' && googleStatus === 'loading' && (
        <div className="absolute inset-0 bg-white/80 dark:bg-slate-900/80 backdrop-blur-xs flex flex-col items-center justify-center gap-2 z-10">
          <div className="w-7 h-7 rounded-full border-3 border-primary border-t-transparent animate-spin" />
          <span className="text-xs font-bold text-ink-secondary dark:text-slate-400">Loading Google Maps...</span>
        </div>
      )}

      {/* Graceful fallback banner if Google Maps fails */}
      {authNotice && activeProvider === 'osm' && (
        <div className="absolute bottom-3 left-3 right-14 z-20 bg-amber-500/90 text-white text-[10px] font-bold px-3 py-1.5 rounded-lg shadow-sm backdrop-blur-xs flex items-center justify-between pointer-events-auto">
          <span>{authNotice}</span>
          <button
            onClick={() => setAuthNotice(null)}
            className="ml-2 underline hover:opacity-80 text-[10px]"
          >
            Dismiss
          </button>
        </div>
      )}
    </div>
  );
}
