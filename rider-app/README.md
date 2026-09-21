# LocalLens Rider Application

The Rider Application is a dedicated interface for local transport drivers and tour shuttles.

> **Note**: Travelers will NOT use this application. This workspace is strictly for driver/rider dispatch and tracking operations.

## Planned Capabilities

When implemented, the Rider App will enable riders to:
- **Receive Ride Requests**: Real-time dispatch notifications when travelers need transit between itinerary stops.
- **Accept / Reject Rides**: Fast decision controls with distance and estimated payout preview.
- **View Pickup & Drop Locations**: Turn-by-turn navigation coordinates and traveler contact proxies.
- **Update Ride Status**: Lifecycle transitions (`ACCEPTED` -> `ARRIVED_AT_PICKUP` -> `IN_TRANSIT` -> `COMPLETED`).
- **Complete Rides & View Earnings**: Summary receipts and trip logs.

## Workspace Structure

```text
rider-app/
├── src/           # Application components, screens, and entrypoint
├── assets/        # Icons, vehicle graphics, map markers
├── services/      # Geolocation streaming and WebSocket dispatch client
├── types/         # Rider domain TypeScript interfaces
├── README.md      # Rider app overview
└── .env.example   # Rider app environment template
```

## Setup & Development (Future)

Dependencies and mobile/web packaging will be initialized when rider feature development begins.
