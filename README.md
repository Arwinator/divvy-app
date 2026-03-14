# Divvy App

Flutter mobile application for Divvy - A bill splitting app with GCash integration.

## Tech Stack

- Flutter 3.x
- MVVM Architecture
- flutter_shadcn_ui (UI components)
- SQLite (Local storage)
- Firebase Cloud Messaging (Push notifications)

## Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Run the app:

```bash
flutter run
```

## Project Structure

```
lib/
├── models/          # Data models
├── views/           # UI screens
├── viewmodels/      # Business logic
├── services/        # API and local services
└── utils/           # Helper functions
```

## Building

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## Testing

Run tests with:

```bash
flutter test
```

## Related Repositories

- Backend API: [divvy-api](https://github.com/yourusername/divvy-api)
