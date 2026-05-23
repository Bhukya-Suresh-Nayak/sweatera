# SweatEra 💪

> AI-powered fitness tracking platform — Real-time exercise detection, GPS running, food AI, leaderboards.

[![Flutter](https://img.shields.io/badge/Flutter-3.32-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth+Firestore-orange?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## ✨ Features

| Feature | Status |
|---------|--------|
| 🔐 Email / Google / Phone Auth | ✅ Phase 1 |
| 📊 Dashboard with streaks & charts | 🔄 Phase 3 |
| 💪 Live pushup / squat / jump detection | 🔄 Phase 4 |
| 🏃 GPS Running Tracker | 🔄 Phase 5 |
| 🍎 AI Food Analyzer (LLM) | 🔄 Phase 6 |
| 🏆 Global Leaderboard | 🔄 Phase 7 |
| 👤 Public/Private Profiles | 🔄 Phase 8 |

---

## 🏗️ Architecture

SweatEra follows **Clean Architecture** with a **Microservices** backend.

```
lib/
├── core/
│   ├── theme/          # Design system (AppTheme)
│   └── shared/         # Shared widgets & utilities
├── features/
│   ├── auth/           # Login, Signup, OTP, Onboarding
│   ├── dashboard/      # Home dashboard
│   ├── workouts/       # Exercise tracking (MediaPipe)
│   ├── running/        # GPS running tracker
│   ├── leaderboard/    # Rankings & streaks
│   ├── ai_assistant/   # LLM food analysis
│   └── profile/        # Public/private profile
├── routes/             # GoRouter navigation
└── firebase_options.dart
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter 3.32+
- Android Studio (for Android development)
- Firebase project (see Firebase Setup below)

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/sweatera.git
cd sweatera

# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

---

## 🔥 Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project called **sweatera**
3. Enable these services:
   - ✅ Authentication (Email, Google, Phone)
   - ✅ Firestore Database
   - ✅ Analytics
   - ✅ Cloud Messaging
4. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
5. Configure Firebase:
   ```bash
   flutterfire configure --project=YOUR_PROJECT_ID
   ```
   This auto-generates `lib/firebase_options.dart`

---

## 🎨 Design System

SweatEra uses a **dark glassmorphism** aesthetic:
- Background: Deep dark (`#0A0A0F`)
- Brand gradient: Violet → Purple → Cyan
- Glassmorphism cards with blur
- Smooth 300ms animations throughout
- Google Inter font

---

## 🛡️ Privacy

SweatEra is **privacy-first**:
- ❌ No video storage
- ❌ No camera stream stored
- ✅ Only exercise counts stored
- ✅ Pose data processed in-memory only

---

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter + Dart |
| State | Riverpod + Flutter Hooks |
| Navigation | GoRouter |
| Backend | FastAPI (Microservices) |
| Database | Firebase Firestore |
| Auth | Firebase Auth |
| AI/CV | MediaPipe + OpenCV |
| LLM | Gemini API |

---

## 📋 Development Phases

- **Phase 1** — Setup + Auth + Login Screen ✅
- **Phase 2** — Authentication (Email, Google, OTP) ✅
- **Phase 3** — Dashboard UI
- **Phase 4** — Live Exercise Tracking (MediaPipe)
- **Phase 5** — GPS Running Tracker
- **Phase 6** — AI Food Analyzer
- **Phase 7** — Leaderboard
- **Phase 8** — Profile System
- **Phase 9** — Optimization

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
