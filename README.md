# JumpIn

Online platforma za oglašavanje i rezervacije za dijeljenje vožnji, iznajmljivanje automobila i iznajmljivanje stanova.

## Tehnologije

- **Backend**: ASP.NET Core 10.0, Entity Framework Core, SQL Server
- **Mobilna aplikacija**: Flutter (Android/iOS)
- **Desktop aplikacija**: Flutter (Windows/macOS/Linux)
- **Message broker**: RabbitMQ
- **Plaćanja**: Stripe
- **Autentifikacija**: JWT + Basic Auth

## Preduslovi

- Docker i Docker Compose
- Flutter SDK (za mobilnu/desktop aplikaciju)
- .NET 10.0 SDK (za lokalni razvoj)

## Pokretanje

### 1. Pokretanje backend servisa pomoću Docker-a

```bash
cd backend
docker-compose up --build
```

Ovo pokreće:
- **API** na `http://localhost:5194`
- **SQL Server** na portu `1434`
- **RabbitMQ** na portu `5672` (Management UI: `http://localhost:15672`)
- **Worker** servis (consumer za e-mail/notifikacije)

### 2. Pokretanje mobilne aplikacije

```bash
cd frontend/jumpin_mobile
flutter pub get
flutter run
```

Sa prilagođenim API URL-om:
```bash
flutter run --dart-define=API_URL=http://10.0.2.2:5194/api
```

### 3. Pokretanje desktop aplikacije

```bash
cd frontend/jumpin_desktop
flutter pub get
flutter run
```

## Testni nalozi

Prijavite se pomoću **e-maila** i lozinke ispod (sve seedovane lozinke su `test1234`).

### Desktop aplikacija (Admin)

| E-mail            | Lozinka  |
|-------------------|----------|
| admin@jumpin.com  | test1234 |

### Mobilna aplikacija (Kupac)

| E-mail            | Lozinka  |
|-------------------|----------|
| mobile@jumpin.com | test1234 |

### Dodatni nalozi (lozinka `test1234`)

| E-mail                    | Uloga       |
|---------------------------|-------------|
| admin@jumpin.com          | Admin       |
| mobile@jumpin.com         | Kupac       |
| alex.carter@gmail.com     | Kupac (VIP) |
| jordan.bennett@gmail.com  | Kupac (VIP) |
| sam.parker@gmail.com      | Kupac       |
| jamie.brooks@gmail.com    | Kupac       |
| chris.morgan@gmail.com    | Kupac       |
| taylor.reed@gmail.com     | Kupac       |
| casey.walker@gmail.com    | Kupac       |
| riley.hayes@gmail.com     | Kupac       |
| morgan.bailey@gmail.com   | Kupac       |
| drew.foster@gmail.com     | Kupac       |

## API dokumentacija

Swagger UI je dostupan na: `http://localhost:5194/swagger`

## Arhitektura

```
JumpIn/
├── backend/
│   ├── JumpIn.API/          # REST API
│   ├── JumpIn.Services/     # Poslovna logika + EF Core
│   ├── JumpIn.Models/       # DTO-ovi, enumi, search objekti
│   └── JumpIn.Worker/       # RabbitMQ consumer (e-mail, notifikacije)
├── frontend/
│   ├── jumpin_mobile/       # Flutter mobilna aplikacija
│   └── jumpin_desktop/      # Flutter desktop admin aplikacija
├── docker-compose.yml
└── README.md
```
