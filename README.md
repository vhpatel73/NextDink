# NextDink 🏓

NextDink is a cross-platform, real-time Pickleball scheduling and matchmaking application built with **Flutter** and powered by **Google Cloud Platform (Firebase)**. 

Find nearby courts, schedule matchups, and seamlessly invite friends to play via native deep links!

## 🚀 Features

* **Secure Authentication**: Frictionless login utilizing Google Identity Services (OAuth 2.0).
* **Interactive Court Discovery**: Integrated Google Maps SDK for visually locating nearby Pickleball parks and facilities.
* **Real-time Matchmaking Dashboard**: Cloud Firestore integration instantly syncs and streams your upcoming booked games natively to your Dashboard.
* **Native Deep Linking**: Generate and share `nextdink-11.web.app/join?gameId=XYZ` links via OS Share Sheets that automatically open the app and group friends into your roster.
* **Cross-Platform Ready**: Designed from the ground up for iOS, Android, and Web deployment.

## 🛠 Tech Stack
* **Frontend**: Flutter / Dart
* **Backend**: Firebase Cloud Firestore
* **Auth**: Firebase Authentication (Google Sign-In)
* **Location APIs**: Google Maps JavaScript SDK / `google_maps_flutter`
* **Routing**: `app_links` Universal Link Interception

## 💻 Local Development Setup

To run this project locally, ensure you have the Flutter SDK installed.

1. **Clone the repository**
2. **Fetch Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run Locally**:
   To test natively on web (recommended local testing target):
   ```bash
   flutter run -d chrome
   ```
   *Note: NextDink intelligently replaces the Google Maps SDK with a fallback interactive mock when testing on localhost to bypass GCP HTTP Referrer limits.*

## 🌐 Production Deployment

NextDink is configured for instantaneous deployment to **Firebase Hosting**.
To push the latest build to the live server:

```bash
flutter build web --release
firebase deploy --only hosting
```

## 📋 Upcoming Roadmap
- [ ] Implement Firebase Cloud Messaging (FCM) Push Notifications.
- [ ] Connect Google Cloud Tasks for absolute 30/15/5 minute pre-game reminders.
- [ ] Finalize native iOS compile targets.
