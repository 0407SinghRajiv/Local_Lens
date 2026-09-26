/**
 * Maps GPS Coordinates (latitude, longitude) centered around Mumbai / MMR
 * to 3D world coordinates [x, y, z] for our low-poly spatial terrain.
 */

// Anchor center: Gateway / South Mumbai - Navi Mumbai zone
const CENTER_LAT = 18.96;
const CENTER_LNG = 72.85;

// Scale factors for visual dispersion on the 3D terrain canvas (range ~ -8 to +8 units)
const SCALE_X = 55; // Longitude east-west
const SCALE_Z = 55; // Latitude north-south

export function coordsTo3D(lat: number, lng: number, terrainHeight = 0.4): [number, number, number] {
  const x = (lng - CENTER_LNG) * SCALE_X;
  const z = -(lat - CENTER_LAT) * SCALE_Z; // In Three.js, -Z is "North"
  return [x, terrainHeight, z];
}

export function threeDToCoords(x: number, z: number): { lat: number; lng: number } {
  const lng = Number((CENTER_LNG + x / SCALE_X).toFixed(6));
  const lat = Number((CENTER_LAT - z / SCALE_Z).toFixed(6));
  return { lat, lng };
}

export function formatINR(amount: number): string {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(amount);
}
