# 🚀 SyncTeam

**Aplikasi Manajemen Tim Multiplatform** — Dibangun dengan Flutter & Supabase

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Academic-blue)]()

> Proyek UAS Mata Kuliah **Pengembangan Aplikasi Berbasis Platform** — Semester 4, Program Studi Informatika, Universitas Siliwangi, 2025.

---

## 📖 Deskripsi

SyncTeam adalah aplikasi manajemen tim multiplatform yang memungkinkan pengguna untuk:

- 📝 **Mendaftar & masuk** ke dalam sistem secara aman
- 👥 **Membuat tim** baru dengan deskripsi, persyaratan, dan tag
- 🔍 **Mencari & melamar** bergabung ke tim yang tersedia
- ✅ **Mengelola anggota** tim (menerima/menolak lamaran)
- 📸 **Mengedit profil** termasuk foto profil
- 🔔 **Menerima notifikasi** real-time saat ada aktivitas tim

Aplikasi tersedia di dua platform: **Android (Mobile)** dan **Web Browser**, dengan satu backend terpadu yang menjamin konsistensi data di kedua platform.

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────────────────────────────────┐
│                   CLIENT LAYER                  │
│  ┌──────────────────┐  ┌──────────────────────┐ │
│  │   Android (APK)  │  │   Web (PWA/Browser)  │ │
│  │   • Kamera       │  │   • Drag & Drop      │ │
│  │   • Native Push  │  │   • Web Push (SW)    │ │
│  └────────┬─────────┘  └──────────┬───────────┘ │
│           │     Flutter (Dart)    │              │
│           └───────────┬───────────┘              │
├───────────────────────┼─────────────────────────┤
│              COMMUNICATION LAYER                │
│           HTTPS/REST  │  WebSocket (WSS)        │
├───────────────────────┼─────────────────────────┤
│                 BACKEND LAYER                   │
│  ┌────────────────────┴────────────────────────┐│
│  │              Supabase (BaaS)                ││
│  │  • Auth (JWT)    • Database (PostgreSQL)    ││
│  │  • Storage       • Realtime Engine          ││
│  │  • Edge Functions                           ││
│  └─────────────────────────────────────────────┘│
├─────────────────────────────────────────────────┤
│               EXTERNAL SERVICES                 │
│         Firebase Cloud Messaging (FCM)          │
└─────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Teknologi | Peran | Keterangan |
|---|---|---|
| **Flutter** | Frontend Framework | Satu codebase untuk Android & Web |
| **Supabase** | Backend-as-a-Service | Auth, Database, Storage, Realtime |
| **Riverpod** | State Management | Mengelola aliran data reaktif di sisi klien |
| **Go Router** | Navigasi | Deep linking, URL management, auth guard |
| **Firebase (FCM)** | Push Notification | Notifikasi ke Android & Web browser |
| **Connectivity Plus** | Network Monitor | Deteksi status online/offline real-time |

---

## 📂 Struktur Proyek

```
lib/
├── core/
│   ├── theme.dart                  # Palet warna, tipografi, konstanta desain
│   ├── router.dart                 # Konfigurasi routing (Go Router)
│   ├── constants.dart              # Supabase URL & anon key
│   ├── connectivity_provider.dart  # Provider status koneksi internet
│   └── side_popup_provider.dart    # Provider state sidebar/popup
│
├── features/
│   ├── auth/                       # Login & registrasi + FCM setup
│   ├── dashboard/                  # Halaman utama & provider tim
│   ├── teams/                      # Daftar, pencarian & detail tim
│   ├── profile/                    # Halaman profil & edit profil
│   └── notifications/              # Halaman & provider notifikasi
│
├── shared/
│   ├── models/                     # Model data (Team, Profile, Notification)
│   └── widgets/                    # Widget bersama (AppScaffold, Sidebar)
│
├── app.dart                        # Root widget MaterialApp
└── main.dart                       # Entry point & Firebase init
```

---

## 📱 Platform-Specific Features

### 🌐 Web
| Fitur | Deskripsi |
|---|---|
| **Drag & Drop Upload** | Seret file gambar langsung ke area foto profil |
| **Progressive Web App (PWA)** | Installable dari browser, berjalan dalam jendela mandiri |
| **Web Push Notification** | Notifikasi browser via Service Worker + FCM |

### 📲 Mobile (Android)
| Fitur | Deskripsi |
|---|---|
| **Akses Kamera** | Ambil foto profil langsung dari kamera perangkat |
| **Native Push Notification** | Notifikasi di system tray via FCM + Android Notification API |

---

## ⚡ Quick Start

### Prasyarat
- Flutter SDK `>= 3.11.4`
- Dart SDK `>= 3.x`
- Akun [Supabase](https://supabase.com) (sudah dikonfigurasi)
- Proyek [Firebase](https://console.firebase.google.com) (untuk FCM)

### Instalasi

```bash
# 1. Clone repository
git clone https://github.com/Sync-Team-Unsil/sync-team-flutter.git
cd sync-team-flutter

# 2. Install dependencies
flutter pub get

# 3. Jalankan di Chrome (Web)
flutter run -d chrome --web-port 8080

# 4. Jalankan di Android
flutter run -d <device_id>

# 5. Build APK Release
flutter build apk --split-per-abi
```

### Konfigurasi
- **Supabase**: Edit `lib/core/constants.dart` untuk URL dan Anon Key.
- **Firebase**: Pastikan `google-services.json` (Android) dan `web/firebase-messaging-sw.js` (Web) sudah sesuai.

---

## 🗄️ Database Schema

```
profiles          teams              team_members        notifications
┌──────────┐     ┌──────────┐       ┌──────────────┐    ┌──────────────┐
│ id (PK)  │◄────│created_by│       │ id (PK)      │    │ id (PK)      │
│ username │     │ id (PK)  │◄──────│ team_id (FK) │    │ user_id (FK) │
│ first_name│     │ name     │       │ user_id (FK) │───►│ type         │
│ last_name│     │ description│      │ role         │    │ title        │
│ avatar_url│     │ requirements│    │ status       │    │ body         │
│ bio      │     │ max_members│      │ joined_at    │    │ is_read      │
│ fcm_token│     │ tags[]   │       └──────────────┘    │ created_at   │
│ role     │     │ created_at│                          └──────────────┘
└──────────┘     └──────────┘
```

---

## 👥 Tim Pengembang

| Nama | NIM | Peran |
|---|---|---|
| **Yusuf Abdurrahman** | 247006111102 | Project Lead & Mobile Developer |
| **Abdurrahman Ali** | 217006054 | Backend Developer |
| **Gema Rais Akbar Pratama** | 247006111107 | Web Developer |
| **Syahiid Idham Al Kholilly** | 247006111120 | UI/UX Engineer & Integration |

---

## 📎 Lampiran

- 🔗 [Video Demonstrasi](https://drive.google.com/drive/folders/1sJng5tLBzSbFulC4zGpGddf1gkGTsVdJ?usp=sharing)

---

## 📄 Lisensi

Proyek ini dikembangkan untuk keperluan akademis — Tugas UAS mata kuliah Pengembangan Aplikasi Berbasis Platform, Universitas Siliwangi, 2026.
