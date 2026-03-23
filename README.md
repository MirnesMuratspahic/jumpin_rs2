# JumpIn

Online marketplace and reservation platform for ride-sharing, car rentals, and apartment rentals.

## Technologies

- **Backend**: ASP.NET Core 8.0, Entity Framework Core, SQL Server
- **Mobile App**: Flutter (Android/iOS)
- **Desktop App**: Flutter (Windows/macOS/Linux)
- **Message Broker**: RabbitMQ
- **Payments**: Stripe
- **Authentication**: JWT + Basic Auth

## Prerequisites

- Docker & Docker Compose
- Flutter SDK (for mobile/desktop apps)
- .NET 8.0 SDK (for local development)

## Getting Started

### 1. Start backend services with Docker

```bash
cd backend
docker-compose up --build
```

This starts:
- **API** on `http://localhost:5194`
- **SQL Server** on port `1433`
- **RabbitMQ** on port `5672` (Management UI: `http://localhost:15672`)
- **Worker** service (email/notification consumer)

### 2. Run the Mobile App

```bash
cd frontend/jumpin_mobile
flutter pub get
flutter run
```

With custom API URL:
```bash
flutter run --dart-define=API_URL=http://10.0.2.2:5194/api
```

### 3. Run the Desktop App

```bash
cd frontend/jumpin_desktop
flutter pub get
flutter run
```

## Test Credentials

### Desktop App (Admin)

| Username | Password |
|----------|----------|
| desktop  | test     |

### Mobile App (Customer)

| Username | Password |
|----------|----------|
| mobile   | test     |

### Additional Accounts

| Username | Password | Role     |
|----------|----------|----------|
| admin    | test     | Admin    |
| mirnes.muratspahic | test | Customer (VIP) |
| sara.hadzic | test | Customer (VIP) |
| amel.music | test | Customer |
| denis.music | test | Customer |
| kenan.begovic | test | Customer |
| amina.causevic | test | Customer |
| edin.spahic | test | Customer |
| lejla.dizdar | test | Customer |
| tarik.mesic | test | Customer |
| nadia.imamovic | test | Customer |

## API Documentation

Swagger UI is available at: `http://localhost:5194/swagger`

## Architecture

```
JumpIn/
├── backend/
│   ├── JumpIn.API/          # REST API
│   ├── JumpIn.Services/     # Business logic + EF Core
│   ├── JumpIn.Models/       # DTOs, Enums, Search objects
│   └── JumpIn.Worker/       # RabbitMQ consumer (email, notifications)
├── frontend/
│   ├── jumpin_mobile/       # Flutter mobile app
│   └── jumpin_desktop/      # Flutter desktop admin app
├── docker-compose.yml
└── README.md
```
