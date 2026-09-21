-- ==============================================================================
-- LocalLens Initial Database Schema
-- Database: PostgreSQL + PostGIS Extension
-- ==============================================================================

-- Enable PostGIS spatial extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Conceptual Entity Stubs (Full DDL will be migrated via Alembic/Flyway)
-- 1. users
-- 2. travelers
-- 3. providers
-- 4. riders
-- 5. locations
-- 6. experiences
-- 7. experience_availability
-- 8. experience_reviews
-- 9. itineraries
-- 10. itinerary_items
-- 11. bookings
-- 12. ride_bookings
-- 13. sponsored_campaigns
-- 14. weather_events
-- 15. traffic_events
-- 16. notifications
