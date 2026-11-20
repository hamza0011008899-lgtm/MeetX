# ⚡ MeetX — Next-Gen Real-Time Messaging App

MeetX is a production-ready, feature-rich real-time messaging, voice, and video calling application built with **Flutter**, **GetX**, and **Supabase** (100% Free-Tier). 

Inspired by WhatsApp's seamless functionality, MeetX features a unique, modern UI with an **Electric Purple & White** design palette (`#6C5CE7`), scalable Clean Architecture, and zero third-party platform costs.

---

## 🎨 Tech Stack & Architecture (100% Free Tier)

| Feature | Technology | Cost |
| :--- | :--- | :--- |
| **Frontend Framework** | [Flutter](https://flutter.dev) (Dart) | Free |
| **State & Navigation** | [GetX](https://pub.dev/packages/get) + Clean Architecture | Free |
| **Backend & Database** | [Supabase](https://supabase.com) (PostgreSQL + Realtime WebSockets) | Free |
| **Authentication** | Supabase Auth (Email, Password, Google OAuth) | Free |
| **Storage & Media** | Supabase Storage (Profile pictures, Voice notes, Attachments) | Free |
| **Theme & Typography** | Material 3 + Google Fonts (`Plus Jakarta Sans`) | Free |
| **Environment Config** | `flutter_dotenv` (`.env`) | Free |

---

## 🏗️ Project Architecture

```
lib/
├── app/
│   ├── data/
│   │   ├── models/            # UserModel (Supabase JSON serialization & copyWith)
│   │   ├── providers/         # Low-level API & Supabase callers
│   │   └── repositories/      # AuthRepository (SignUp, SignIn, Google OAuth, Reset Password)
│   ├── modules/
│   │   ├── auth/              # AuthView & AuthController (Animated Tab Switcher, On-type Validation)
│   │   ├── home/              # HomeView (User Session Card & Confirmation Logout Dialog)
│   │   └── splash/            # SplashView & SplashController (Animated Scale/Pulsing Glow Entrance)
│   ├── routes/
│   │   ├── app_pages.dart     # Dynamic Route Mapping & GetPages
│   │   └── app_routes.dart    # Route Paths Constants
│   ├── services/
│   │   ├── auth_service.dart     # Global Auth State Listener & Session Rx<UserModel?>
│   │   └── supabase_service.dart # Global Supabase & DotEnv Service
│   ├── theme/
│   │   ├── app_colors.dart    # Electric Purple & Dark Violet Palette
│   │   └── app_theme.dart     # Light & Dark Material3 ThemeData
│   └── widgets/
│       └── google_logo.dart   # Vector-sharp 4-Color Official Google Logo
└── main.dart                  # App Entry Point & Service Binding
```

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.12+ recommended)
- Android Studio / VS Code
- A free [Supabase](https://supabase.com) account

### 2. Setup Environment Variables
Create a `.env` file in the root directory (based on `.env.example`):
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-publishable-key
```

### 3. Run Database Migrations
Execute the SQL schema provided in Supabase SQL Editor to initialize `profiles`, `chats`, `chat_participants`, `messages` tables and Realtime replication.

### 4. Install & Run App
```bash
flutter pub get
flutter run
```

---

## 📋 Development Roadmap

- [x] **Phase 1: Foundation & Infrastructure**
  - Clean Architecture & Folder Structure setup
  - Electric Purple (`#6C5CE7`) Light & Dark ThemeData
  - GetX Route Management & Dependency Injection
  - Supabase integration with `.env` credential management
  - PostgreSQL Schema with RLS Policies & Realtime Replication
- [x] **Phase 2: Authentication & User Profiles**
  - Data Layer: `UserModel` (with `fromJson`, `toJson`, `copyWith`) & `AuthRepository`
  - Global State: `AuthService` (`GetxService`) with real-time `onAuthStateChange` listener
  - Animated Entrance Splash Screen (`SplashView` with glowing pulsing logo)
  - Glassmorphic Auth Screen (`AuthView` with tab switcher & automatic focus request)
  - Real-time On-type Form Validation (Email regex, Password length, Username rules)
  - Custom vector 4-color Google Logo & OAuth deep-linking callback (`io.supabase.meetx://login-callback`)
  - Forgot Password Flow (Deep-linked password reset emails)
  - First-time Email Verification Dialog & Confirmation Flow
  - Session Logout confirmation dialog on `HomeView`
- [ ] **Phase 3: Realtime 1-on-1 Chat System**
- [ ] **Phase 4: Voice Notes & Media Sharing**
- [ ] **Phase 5: Push Notifications & Deep Linking**
- [ ] **Phase 6: WebRTC Audio & Video Calling**
- [ ] **Phase 7: AI Suggested Replies (Gemini API)**

---

## 📜 License
This project is open-source and free to use.
