# ⚡ MeetX — Next-Gen Real-Time Messaging App

MeetX is a production-ready, feature-rich real-time messaging, voice, and video calling application built with **Flutter**, **GetX**, and **Supabase** (100% Free-Tier). 

Inspired by WhatsApp's seamless functionality, MeetX features a unique, modern UI with an **Electric Purple & White** design palette, scalable Clean Architecture, and zero third-party platform costs.

---

## 🎨 Tech Stack & Architecture (100% Free Tier)

| Feature | Technology | Cost |
| :--- | :--- | :--- |
| **Frontend Framework** | [Flutter](https://flutter.dev) (Dart) | Free |
| **State & Navigation** | [GetX](https://pub.dev/packages/get) + Clean Architecture | Free |
| **Backend & Database** | [Supabase](https://supabase.com) (PostgreSQL + Realtime WebSockets) | Free |
| **Authentication** | Supabase Auth (Email, Password, Social Auth) | Free |
| **Storage & Media** | Supabase Storage (Profile pictures, Voice notes, Attachments) | Free |
| **Theme & Typography** | Material 3 + Google Fonts (`Plus Jakarta Sans`) | Free |
| **Environment Config** | `flutter_dotenv` (`.env`) | Free |

---

## 🏗️ Project Architecture

```
lib/
├── app/
│   ├── data/
│   │   ├── models/            # Data Models (UserModel, MessageModel, ChatModel)
│   │   ├── providers/         # Low-level API & Supabase callers
│   │   └── repositories/      # Domain Repositories (AuthRepository, ChatRepository)
│   ├── modules/
│   │   └── home/
│   │       └── views/
│   │           └── home_view.dart  # Home Screen View
│   ├── routes/
│   │   ├── app_pages.dart     # Route mapping & GetPages definition
│   │   └── app_routes.dart    # Route paths constants
│   ├── services/
│   │   └── supabase_service.dart  # Global Supabase & DotEnv Service
│   └── theme/
│       ├── app_colors.dart    # Electric Purple & Dark Violet Palette
│       └── app_theme.dart     # Light & Dark Material3 ThemeData
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
- [ ] **Phase 2: Authentication & User Profiles**
- [ ] **Phase 3: Realtime 1-on-1 Chat System**
- [ ] **Phase 4: Voice Notes & Media Sharing**
- [ ] **Phase 5: Push Notifications & Deep Linking**
- [ ] **Phase 6: WebRTC Audio & Video Calling**
- [ ] **Phase 7: AI Suggested Replies (Gemini API)**

---

## 📜 License
This project is open-source and free to use.
