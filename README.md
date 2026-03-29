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

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)

2. **Android Setup:**
   - Download `google-services.json` from Firebase Console
   - Place it in `android/app/`

3. **iOS Setup (if building for iOS):**
   - Download `GoogleService-Info.plist` from Firebase Console
   - Place it in `ios/Runner/`

4. **Generate Firebase Options:**
   - Copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart`
   - Run `flutterfire configure` to auto-generate configuration
   - OR manually fill in your Firebase project details in `firebase_options.dart`

   ```dart
   static const FirebaseOptions android = FirebaseOptions(
     apiKey: 'YOUR_API_KEY',
     appId: 'YOUR_APP_ID',
     messagingSenderId: 'YOUR_SENDER_ID',
     projectId: 'YOUR_PROJECT_ID',
     storageBucket: 'YOUR_STORAGE_BUCKET',
   );
   ```

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
