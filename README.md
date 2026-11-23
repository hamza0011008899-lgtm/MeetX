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
│   │   ├── models/            # UserModel, ChatModel, MessageModel
│   │   ├── providers/         # Low-level API & Supabase callers
│   │   └── repositories/      # AuthRepository & ChatRepository (Realtime & Queries)
│   ├── modules/
│   │   ├── auth/              # AuthView & AuthController
│   │   ├── chat/              # ChatView, UserSearchView, GroupCreateView & Controllers
│   │   ├── home/              # HomeView & HomeController (Conversations & Unread Badges)
│   │   └── splash/            # SplashView & SplashController
│   ├── routes/
│   │   ├── app_pages.dart     # Dynamic Route Mapping & GetPages
│   │   └── app_routes.dart    # Route Paths Constants
│   ├── services/
│   │   ├── auth_service.dart     # Global Auth State Listener & Presence Manager
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
  - Data Layer: `UserModel` & `AuthRepository`
  - Global State: `AuthService` (`GetxService`) with real-time `onAuthStateChange` listener
  - Animated Entrance Splash Screen (`SplashView`)
  - Glassmorphic Auth Screen (`AuthView` with tab switcher & auto-focus)
  - Real-time On-type Form Validation
  - Custom vector 4-color Google Logo & OAuth deep-linking
  - Forgot Password Flow & First-time Email Verification Dialog
- [x] **Phase 3: Realtime 1-on-1 & Group Chat System**
  - Data Models: `MessageModel` & `ChatModel` (supports 1-on-1 private & Group chats)
  - Data Repository: `ChatRepository` (search users, create chats, fetch history, Realtime WebSockets)
  - Live User Search (`UserSearchView` with debounced search)
  - Realtime Chat Screen (`ChatView` with Electric Purple bubbles, timestamps & blue ticks)
  - Live Typing Indicator (`"typing..."` broadcast stream)
  - Message Long-Press Menu (Copy text & Delete message for everyone)
  - Online / Offline Status Presence tracking (`WidgetsBindingObserver`)
  - Group Chat Creation (`GroupCreateView` with multi-member selector)
  - Active Conversations List on `HomeView` with unread badge counters
- [ ] **Phase 4: Voice Notes & Media Sharing**
- [ ] **Phase 5: Push Notifications & Deep Linking**
- [ ] **Phase 6: WebRTC Audio & Video Calling**
- [ ] **Phase 7: AI Suggested Replies (Gemini API)**

---

## 📜 License
This project is open-source and free to use.
