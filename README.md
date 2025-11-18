# Hofra - Report Road Problems

A Flutter app that helps drivers report road holes and problems with just a few taps. Each report includes the location, photos, and a description so authorities can quickly identify and fix the problem. Designed especially for motorcyclists who face daily risks, the app improves safety for everyone on the road.

## Features

- ✅ **User Authentication**: Register and login with email/password
- ✅ **Google Maps Integration**: View map with your current location
- ✅ **Report Road Problems**: Report holes and issues at specific locations
- ✅ **Photo Upload**: Take up to 3 photos per report
- ✅ **Community Confirmation**: Other users can confirm reports exist
- ✅ **Fixed Status**: Users can mark reports as fixed
- ✅ **User Statistics**: Track your reported, fixed, and pending reports
- ✅ **Real-time Updates**: See reports on the map in real-time

## Screenshots

*Add screenshots here once the app is running*

## Setup Instructions

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Android Studio / Xcode
- Firebase account
- Google Cloud Platform account

### Step 1: Clone and Install Dependencies

```bash
cd hofra
flutter pub get
```

### Step 2: Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android app with package name: `com.hofra.app`
3. Add iOS app with your bundle ID
4. Download configuration files:
   - `google-services.json` → Place in `android/app/`
   - `GoogleService-Info.plist` → Place in `ios/Runner/`
5. Enable Firebase services:
   - Authentication → Email/Password
   - Firestore Database → Create database
   - Storage → Get started

### Step 3: Google Maps API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
3. Create API Key and restrict it
4. Update API keys:
   - **Android**: Edit `android/app/src/main/AndroidManifest.xml` (replace `YOUR_GOOGLE_MAPS_API_KEY`)
   - **iOS**: Add to `ios/Runner/AppDelegate.swift`

### Step 4: Run the App

```bash
flutter run
```

For detailed setup instructions, see [SETUP.md](SETUP.md)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── report_model.dart     # Report data model
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── map/
│   │   └── map_screen.dart
│   ├── report/
│   │   └── report_screen.dart
│   └── account/
│       └── account_screen.dart
├── services/
│   ├── auth_service.dart     # Authentication service
│   └── report_service.dart   # Report management service
└── widgets/
    └── report_info_bottom_sheet.dart
```

## Firestore Structure

### Collection: `reports`

```javascript
{
  userId: string,
  userName: string,
  latitude: number,
  longitude: number,
  description: string,
  images: string[],
  status: 'pending' | 'confirmed' | 'fixed',
  confirmations: number,
  fixedConfirmations: number,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Subcollection: `reports/{reportId}/confirmations`

```javascript
{
  userId: string,
  type: 'confirm' | 'fixed',
  createdAt: timestamp
}
```

## Security Rules

See [SETUP.md](SETUP.md) for Firestore and Storage security rules.

## Technologies Used

- **Flutter**: Cross-platform mobile framework
- **Firebase**: Backend services (Auth, Firestore, Storage)
- **Google Maps**: Map display and location services
- **Provider**: State management
- **Image Picker**: Camera and gallery access
- **Geolocator**: Location services

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Support

For issues and questions, please open an issue on GitHub.
