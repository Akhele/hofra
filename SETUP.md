# Hofra App Setup Guide

This guide will help you set up the Hofra app with Firebase and Google Maps API.

## Prerequisites

- Flutter SDK installed (3.0.0 or higher)
- Android Studio / Xcode installed
- Firebase account
- Google Cloud Platform account

## Step 1: Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Add Android and iOS apps to your Firebase project:
   - **Android**: Package name should be `com.hofra.app`
   - **iOS**: Bundle ID should match your iOS app bundle ID

4. Download configuration files:
   - **Android**: Download `google-services.json` and place it in `android/app/`
   - **iOS**: Download `GoogleService-Info.plist` and place it in `ios/Runner/`

5. Enable Firebase services:
   - Go to Authentication → Sign-in method → Enable Email/Password
   - Go to Firestore Database → Create database (Start in test mode)
   - Go to Storage → Get started (Start in test mode)

## Step 2: Google Maps API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
   - Places API (optional, for future enhancements)

4. Create API credentials:
   - Go to APIs & Services → Credentials
   - Create API Key
   - Restrict the key to your app's package name (Android) and bundle ID (iOS)

5. Update API keys:
   - **Android**: Edit `android/app/src/main/AndroidManifest.xml` and replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key
   - **iOS**: Edit `ios/Runner/AppDelegate.swift` and add your API key in the `application:didFinishLaunchingWithOptions` method

## Step 3: iOS Configuration (if building for iOS)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Add your Google Maps API key in `AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
   ```

3. Update `ios/Podfile` to ensure Google Maps is included:
   ```ruby
   pod 'GoogleMaps'
   pod 'Google-Maps-iOS-Utils'
   ```

4. Run `pod install` in the `ios` directory

## Step 4: Android Configuration

1. Ensure `google-services.json` is in `android/app/`
2. Update `android/app/src/main/AndroidManifest.xml` with your Google Maps API key
3. Make sure `minSdkVersion` is set to 21 or higher

## Step 5: Install Dependencies

Run the following command in the project root:

```bash
flutter pub get
```

## Step 6: Run the App

For Android:
```bash
flutter run
```

For iOS:
```bash
flutter run
```

## Firestore Security Rules

Update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /reports/{reportId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
      
      match /confirmations/{confirmationId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
      }
    }
  }
}
```

## Firebase Storage Security Rules

Update your Storage security rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /reports/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.resource.size < 5 * 1024 * 1024; // 5MB max
    }
  }
}
```

## Troubleshooting

1. **Maps not showing**: Check that your Google Maps API key is correctly set and the APIs are enabled
2. **Location not working**: Ensure location permissions are granted in device settings
3. **Firebase errors**: Verify that `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in the correct locations
4. **Image upload fails**: Check Firebase Storage rules and ensure images are under 5MB

## Features

- ✅ User authentication (Email/Password)
- ✅ Google Maps integration with user location
- ✅ Report road problems with location
- ✅ Upload up to 3 photos per report
- ✅ Confirm reports (other users can confirm holes exist)
- ✅ Mark reports as fixed
- ✅ User statistics (reported, fixed, pending)
- ✅ Real-time updates on map

## Next Steps

- Add push notifications for report updates
- Add admin panel for authorities
- Add report categories
- Add comments on reports
- Add report history timeline

