"use client";

import React, { useEffect } from "react";
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

// Fix standard Leaflet default icon URL issues with Next.js webpack
const defaultIcon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

interface LeafletPinDropperProps {
  position: { lat: number; lng: number };
  onPinSelected: (coords: { lat: number; lng: number }) => void;
  venueName?: string;
}

const LocationPicker: React.FC<{
  position: { lat: number; lng: number };
  onPinSelected: (coords: { lat: number; lng: number }) => void;
  venueName?: string;
}> = ({ position, onPinSelected, venueName = "Selected Venue" }) => {
  const markerRef = React.useRef<any>(null);

  const map = useMapEvents({
    click(e) {
      const lat = Number(e.latlng.lat.toFixed(6));
      const lng = Number(e.latlng.lng.toFixed(6));
      onPinSelected({ lat, lng });
      map.flyTo(e.latlng, map.getZoom());
    },
  });

  useEffect(() => {
    map.flyTo([position.lat, position.lng], map.getZoom());
  }, [position.lat, position.lng, map]);

  const eventHandlers = React.useMemo(
    () => ({
      dragend() {
        const marker = markerRef.current;
        if (marker != null) {
          const latLng = marker.getLatLng();
          const lat = Number(latLng.lat.toFixed(6));
          const lng = Number(latLng.lng.toFixed(6));
          onPinSelected({ lat, lng });
        }
      },
    }),
    [onPinSelected]
  );

  return (
    <Marker
      draggable={true}
      eventHandlers={eventHandlers}
      position={[position.lat, position.lng]}
      icon={defaultIcon}
      ref={markerRef}
    />
  );
};

export const LeafletPinDropper: React.FC<LeafletPinDropperProps> = ({
  position,
  onPinSelected,
  venueName = "Selected Venue",
}) => {
  return (
    <div className="w-full h-full min-h-[300px] rounded-2xl overflow-hidden border border-slate-200 relative shadow-inner z-0">
      <MapContainer
        center={[position.lat, position.lng]}
        zoom={14}
        scrollWheelZoom={true}
        style={{ height: "100%", width: "100%" }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <LocationPicker position={position} onPinSelected={onPinSelected} venueName={venueName} />
      </MapContainer>
      <div className="absolute bottom-2.5 left-2.5 z-[400] bg-slate-900/85 text-white text-[10.5px] font-mono px-2.5 py-1 rounded-lg backdrop-blur-md border border-white/10 shadow-sm pointer-events-none">
        {position.lat.toFixed(6)}, {position.lng.toFixed(6)}
      </div>
      <div className="absolute top-2.5 left-2.5 z-[400] bg-white/95 backdrop-blur-md px-2.5 py-1 rounded-xl shadow-md border border-slate-200/80 flex items-center gap-1.5 pointer-events-none">
        <span className="w-2 h-2 rounded-full bg-[#0e8a5b] animate-pulse" />
        <span className="text-[11px] font-extrabold text-slate-800 tracking-tight">
          Interactive Map
        </span>
        <span className="text-[10px] text-slate-400 font-medium">|</span>
        <span className="text-[10px] text-[#0e8a5b] font-bold">
          Click or Drag Pin
        </span>
      </div>
    </div>
  );
};