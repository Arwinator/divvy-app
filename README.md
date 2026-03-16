# Divvy App

> Mobile app for Divvy, a bill splitting app.

**⚠️ Work in Progress** - Actively being developed.

## Overview

Bill splitting app targeting the Philippine market. Split expenses with friends and pay through GCash or PayMaya.

## Features

- User authentication and registration
- Create and manage groups
- Split bills equally or set custom amounts
- Process payments via GCash and PayMaya
- Track transaction history
- Push notifications for bill updates
- Offline sync support

## Tech Stack

- Flutter 3.x
- MVVM Architecture
- SQLite (local storage)
- Firebase Cloud Messaging (push notifications)
- Material Design 3 (UI components)
- connectivity_plus (network monitoring)

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Android Studio / Xcode
- Firebase project
- Backend API running

### Installation

Clone the repository:

```bash
git clone https://github.com/Arwinator/divvy-app.git
cd divvy-app
```

Install dependencies:

```bash
flutter pub get
```

Configure environment:

Update `lib/core/config/environment.dart` with your API base URL:

```dart
static const String apiBaseUrl = 'http://your-api-url/api';
```

**Firebase Configuration**

- Download `google-services.json` (Android) from Firebase Console
- Place it in `android/app/`
- Download `GoogleService-Info.plist` (iOS) from Firebase Console
- Place it in `ios/Runner/`

Run the app:

```bash
flutter run
```

## Architecture

- **MVVM Pattern** for separation of concerns
- **Repository Pattern** for data access
- **Offline-First** with SQLite caching
- **Service Layer** for API communication
- **ChangeNotifier** for state management

## Testing

```bash
flutter test
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

## Known Limitations

Some features are not yet implemented:

- Account deletion
- Bill editing after creation
- Group ownership transfer
- Receipt photo upload
- Payment reminders

## Related

- Backend API: [divvy-api](https://github.com/Arwinator/divvy-api) (Laravel, in progress)

---

**Built by [@Arwinator](https://github.com/Arwinator)**
