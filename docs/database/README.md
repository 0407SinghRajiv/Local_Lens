# LocalLens Database Architecture

The data persistence tier uses PostgreSQL with PostGIS extensions to support location-aware operations.

## Database Entities

- `users`: Core authentication identity
- `travelers`: Traveler personal preferences and settings
- `providers`: Local tour and experience hosts
- `riders`: Transport drivers
- `locations`: Geospatial coordinate records (`GEOMETRY(Point, 4326)`)
- `experiences`: Activities, tours, and culinary events
- `experience_availability`: Time slots and reservation quotas
- `experience_reviews`: Traveler feedback and scores
- `itineraries`: Dynamic travel plans
- `itinerary_items`: Specific scheduled stops within an itinerary
- `bookings`: Experience reservations
- `ride_bookings`: Transportation transit between itinerary waypoints
- `sponsored_campaigns`: Local business promotions
- `weather_events`: Weather disruption notices
- `traffic_events`: Congestion and transit notices
- `notifications`: Push and application alerts

## Initial Schema Initialization

Schema extensions and initial tables are loaded via `database/schema.sql` during Docker container initialization.
