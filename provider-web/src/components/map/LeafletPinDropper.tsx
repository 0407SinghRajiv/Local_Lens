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
}

const LocationPicker: React.FC<{
  position: { lat: number; lng: number };
  onPinSelected: (coords: { lat: number; lng: number }) => void;
}> = ({ position, onPinSelected }) => {
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
  }, [position, map]);

  return <Marker position={[position.lat, position.lng]} icon={defaultIcon} />;
};

export const LeafletPinDropper: React.FC<LeafletPinDropperProps> = ({
  position,
  onPinSelected,
}) => {
  return (
    <div className="w-full h-72 rounded-2xl overflow-hidden border border-slate-200 relative shadow-inner z-0">
      <MapContainer
        center={[position.lat, position.lng]}
        zoom={13}
        scrollWheelZoom={true}
        style={{ height: "100%", width: "100%" }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <LocationPicker position={position} onPinSelected={onPinSelected} />
      </MapContainer>
      <div className="absolute bottom-2 left-2 z-[400] bg-slate-900/90 text-white text-[10px] font-bold px-2.5 py-1 rounded-lg backdrop-blur-md border border-white/20">
        Click anywhere on the map to set exact coordinates
      </div>
    </div>
  );
};