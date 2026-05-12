# SyncTeam — PRD & AI Coding Instructions
> Deadline: ~20 jam dari sekarang. Baca semua bagian sebelum mulai nulis kode.

---

## 1. OVERVIEW APLIKASI

**Nama:** SyncTeam  
**Tagline:** Manage your teams, stay in sync.  
**Platform:** Web (Flutter Web, fokus desktop) + Mobile (Flutter Android/iOS)  
**Backend:** Supabase (Auth + PostgreSQL + Realtime)  
**Bahasa:** Dart / Flutter

SyncTeam adalah aplikasi manajemen tim sederhana. Pengguna bisa login, melihat daftar tim yang diikuti, membuat tim baru, dan mengelola profil mereka.

---

## 2. SCOPE FITUR (MINIMAL, SESUAI KETENTUAN)

### Halaman / Screen
1. **Auth Screen** — Login & Register (email + password, tanpa OTP)
2. **Dashboard Screen** — Daftar tim yang diikuti user
3. **Profile Screen** — Info profil user

### Side Popup / Drawer (bukan halaman baru)
- **Team Detail Popup** — Muncul dari kanan saat tap/klik sebuah tim (slide-in panel)
- **Create Team Popup** — Form input nama tim baru (slide-in panel)
- **Edit Profile Popup** — Form edit nama & avatar (slide-in panel)

### Tidak perlu
- OTP / email verification
- Fitur aneh-aneh lain
- Multiple role / permission
- Chat / messaging

---

## 3. PLATFORM-SPECIFIC FEATURES (WAJIB)

### Mobile (Android/iOS)
**Fitur: Push Notification**
- Saat user berhasil membuat tim baru, semua member tim yang ada mendapat push notification: *"[Nama Tim] baru telah dibuat oleh [username]"*
- Menggunakan package `firebase_messaging` (FCM)
- Notifikasi muncul di system tray HP meski app sedang di-background / tertutup
- Ini adalah fitur yang tidak bisa direplikasi identik di web dalam proyek ini

### Web (Desktop-focused)
**Fitur: PWA (Progressive Web App) — Installable + Offline**
- App bisa di-install ke desktop browser (Chrome/Edge)
- Ada manifest.json dan service worker
- Halaman dashboard tetap tampil (dengan data cache) saat offline
- Di Flutter Web: aktifkan PWA support di `web/manifest.json` dan `flutter_service_worker.js`
- Ini platform-specific karena mobile app sudah native, bukan PWA

---

## 4. TECH STACK

| Layer | Teknologi | Alasan |
|---|---|---|
| Frontend (semua platform) | Flutter 3.x | Satu codebase, beda UI per platform |
| Backend | Supabase | Auth built-in, PostgreSQL, free tier cukup |
| State Management | Riverpod (atau Provider) | Reaktif, cocok untuk auth state |
| Local Auth | `local_auth` package | Biometric untuk mobile |
| PWA | Flutter Web built-in + custom manifest | Offline + installable untuk web |
| HTTP | Supabase Dart client (`supabase_flutter`) | Official, sudah handle auth token |

---

## 5. DATABASE SCHEMA (Supabase)

### Tabel: `profiles`
```sql
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  username text,
  avatar_url text,
  created_at timestamp with time zone default now()
);

-- RLS
alter table profiles enable row level security;
create policy "Users can view own profile" on profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
```

### Tabel: `teams`
```sql
create table teams (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  created_by uuid references auth.users not null,
  created_at timestamp with time zone default now()
);

alter table teams enable row level security;
create policy "Anyone can view teams" on teams for select using (true);
create policy "Users can create teams" on teams for insert with check (auth.uid() = created_by);
create policy "Creator can update team" on teams for update using (auth.uid() = created_by);
```

### Tabel: `team_members`
```sql
create table team_members (
  id uuid default gen_random_uuid() primary key,
  team_id uuid references teams on delete cascade not null,
  user_id uuid references auth.users on delete cascade not null,
  joined_at timestamp with time zone default now(),
  unique(team_id, user_id)
);

alter table team_members enable row level security;
create policy "Members can view team memberships" on team_members for select using (true);
create policy "Users can join teams" on team_members for insert with check (auth.uid() = user_id);
create policy "Users can leave teams" on team_members for delete using (auth.uid() = user_id);
```

---

## 6. STRUKTUR FOLDER FLUTTER

```
syncteam/
├── lib/
│   ├── main.dart
│   ├── app.dart                        # MaterialApp / routing
│   ├── core/
│   │   ├── supabase_client.dart        # init supabase
│   │   ├── router.dart                 # GoRouter config
│   │   └── theme.dart                  # AppTheme (web vs mobile)
│   ├── features/
│   │   ├── auth/
│   │   │   ├── auth_screen.dart        # Login + Register tabs
│   │   │   ├── auth_provider.dart      # Riverpod auth state
│   │   │   └── fcm_service.dart        # MOBILE ONLY — push notification
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart   # Layout beda web/mobile
│   │   │   ├── team_card.dart
│   │   │   ├── team_detail_panel.dart  # Side popup
│   │   │   └── create_team_panel.dart  # Side popup
│   │   └── profile/
│   │       ├── profile_screen.dart
│   │       └── edit_profile_panel.dart # Side popup
│   └── shared/
│       ├── widgets/
│       │   ├── side_panel.dart         # Reusable slide-in panel wrapper
│       │   └── app_scaffold.dart       # Scaffold dengan nav
│       └── models/
│           ├── team.dart
│           └── profile.dart
├── web/
│   ├── manifest.json                   # PWA manifest
│   ├── index.html
│   └── flutter_service_worker.js       # auto-generated, pastikan aktif
└── pubspec.yaml
```

---

## 7. PUBSPEC.YAML DEPENDENCIES

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  firebase_messaging: ^14.0.0  # MOBILE ONLY (platform-specific feature)
  firebase_core: ^2.24.0
  cached_network_image: ^3.3.0
  image_picker: ^1.0.0         # untuk ganti avatar

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## 8. PERBEDAAN UI WEB vs MOBILE (PENTING!)

### Web (Desktop Layout)
```
┌─────────────────────────────────────────────────────┐
│ [SyncTeam Logo]              [Profile Avatar]       │  ← Top AppBar
├──────────┬──────────────────────────────────────────┤
│          │                                          │
│  NAV     │   CONTENT AREA                           │
│          │                                          │
│ Dashboard│   Dashboard: Grid of team cards (3 col)  │
│ Profile  │                                          │
│          │   [+ New Team] button (top right)        │
│          │                                          │
└──────────┴──────────────────────────────────────────┘
                                    ↓ klik team card
                         ┌─────────────────────┐
                         │ SIDE PANEL (kanan)   │
                         │ Team detail / form  │
                         └─────────────────────┘
```

- Layout: `Row` dengan `NavigationRail` di kiri + content di kanan
- Team cards: `GridView` 3 kolom
- Side panel: overlay `AnimatedContainer` dari kanan (lebar 380px)
- Tidak ada bottom navigation bar

### Mobile Layout
```
┌─────────────────┐
│ SyncTeam   [+]  │  ← AppBar
├─────────────────┤
│                 │
│  Team Card      │
│  Team Card      │  ← ListView 1 kolom
│  Team Card      │
│                 │
├─────────────────┤
│ [Home] [Profile]│  ← BottomNavigationBar
└─────────────────┘
         ↓ tap team card
┌─────────────────┐
│ BOTTOM SHEET    │  ← DraggableScrollableSheet
│ atau modal      │
│ team detail     │
└─────────────────┘
```

- Layout: `Scaffold` dengan `BottomNavigationBar`
- Team cards: `ListView` 1 kolom
- Side panel: `showModalBottomSheet` (bukan side panel, karena layar sempit)
- Biometric login prompt saat app launch

---

## 9. IMPLEMENTASI DETAIL

### 9.1 Supabase Init (`main.dart`)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  runApp(ProviderScope(child: MyApp()));
}
```

### 9.2 Auth Screen
- 2 tab: Login | Register
- Login: email + password → `supabase.auth.signInWithPassword()`
- Register: email + password → `supabase.auth.signUp()`
- Tidak ada OTP, tidak ada email verification (disable di Supabase dashboard: Auth > Email > "Confirm email" = OFF)
- Redirect ke `/dashboard` setelah sukses

### 9.3 GoRouter Config
```dart
final router = GoRouter(
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isOnAuth = state.matchedLocation == '/auth';
    if (!isLoggedIn && !isOnAuth) return '/auth';
    if (isLoggedIn && isOnAuth) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (_, __) => AuthScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),
    GoRoute(path: '/profile', builder: (_, __) => ProfileScreen()),
  ],
);
```

### 9.4 FCM Push Notification Service (MOBILE ONLY)

**Setup Firebase:**
1. Buat project di [Firebase Console](https://console.firebase.google.com)
2. Tambah Android app (package name sesuai flutter project, cek `android/app/build.gradle`)
3. Download `google-services.json` → taruh di `android/app/`
4. Di `android/build.gradle` tambah: `classpath 'com.google.gms:google-services:4.4.0'`
5. Di `android/app/build.gradle` tambah di paling bawah: `apply plugin: 'com.google.gms.google-services'`

```dart
// lib/features/auth/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Background handler — harus top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM akan tampilkan notif otomatis di background
  print('Background message: ${message.notification?.title}');
}

class FcmService {
  static bool get isSupported => !kIsWeb;

  static Future<void> init() async {
    if (!isSupported) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission();
  }

  static Future<String?> getToken() async {
    if (!isSupported) return null;
    return await FirebaseMessaging.instance.getToken();
  }

  static void listenForeground() {
    if (!isSupported) return;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Tampilkan snackbar atau local notification saat app foreground
      print('Foreground message: ${message.notification?.title}');
    });
  }
}
```

**Simpan FCM token ke Supabase (tambah kolom `fcm_token` di tabel `profiles`):**
```sql
alter table profiles add column fcm_token text;
```

```dart
// Setelah login, simpan token
final token = await FcmService.getToken();
if (token != null) {
  await Supabase.instance.client
    .from('profiles')
    .update({'fcm_token': token})
    .eq('id', Supabase.instance.client.auth.currentUser!.id);
}
```

**Trigger notifikasi saat buat tim baru:**
Kirim notifikasi via Supabase Edge Function atau langsung dari Flutter ke FCM HTTP API.
Cara paling simpel: setelah `insert` tim baru berhasil, panggil FCM REST API ke semua token member.

```dart
// Simpel: kirim notif ke diri sendiri dulu (demo purpose)
// Untuk production: Supabase Edge Function yang broadcast ke semua member
Future<void> sendNewTeamNotification(String teamName, String fcmToken) async {
  // Panggil Supabase Edge Function yang handle pengiriman FCM
  await Supabase.instance.client.functions.invoke(
    'send-notification',
    body: {
      'token': fcmToken,
      'title': 'Tim Baru Dibuat!',
      'body': 'Tim "$teamName" telah dibuat.',
    },
  );
}
```

**Cara init di `main.dart`:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp();
    await FcmService.init();
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(ProviderScope(child: MyApp()));
}
```

### 9.5 Side Panel Widget (reusable)
```dart
// lib/shared/widgets/side_panel.dart
class SidePanel extends StatelessWidget {
  final bool isOpen;
  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: isOpen ? 0 : -400,
      top: 0,
      bottom: 0,
      width: 380,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black26)],
        ),
        child: child,
      ),
    );
  }
}
```

### 9.6 PWA Setup (WEB ONLY)
Di `web/manifest.json`:
```json
{
  "name": "SyncTeam",
  "short_name": "SyncTeam",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#1a1a2e",
  "theme_color": "#4f46e5",
  "description": "Manage your teams, stay in sync.",
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

Di `web/index.html`, pastikan ada:
```html
<link rel="manifest" href="manifest.json">
<meta name="theme-color" content="#4f46e5">
```

Flutter Web secara otomatis generate service worker saat `flutter build web`. Untuk offline support, tambahkan di `flutter_service_worker.js` atau gunakan plugin `pwa` jika perlu custom cache strategy.

---

## 10. DESIGN SYSTEM (Berdasarkan Figma Reference)

### Color Palette
```dart
// lib/core/theme.dart
const primaryColor = Color(0xFF4F46E5);      // Indigo
const surfaceColor = Color(0xFF1E1E2E);      // Dark surface
const cardColor = Color(0xFF2A2A3E);         // Card bg
const textPrimary = Color(0xFFE8E8F0);       // Light text
const textSecondary = Color(0xFF9090A8);     // Muted text
const accentColor = Color(0xFF7C3AED);       // Purple accent
```

### Komponen Utama
- **Team Card**: Rounded corners, gradient subtle, nama tim + jumlah member + icon
- **Side Panel**: Slide dari kanan (web) / bottom sheet (mobile), shadow tebal
- **FAB / Button**: Rounded, warna primary, icon + label
- **Avatar**: CircleAvatar dengan fallback initials

---

## 11. ALUR DATA (Data Flow)

```
User Action
    │
    ▼
Flutter Widget (UI)
    │
    ▼
Riverpod Provider (State)
    │
    ▼
Supabase Dart Client
    │
    ▼
Supabase Backend (Auth / PostgreSQL)
    │
    ▼ (response)
Riverpod Provider update state
    │
    ▼
Widget rebuild
```

### Provider Contoh
```dart
// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

// Teams provider
final teamsProvider = FutureProvider<List<Team>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser!.id;
  final res = await Supabase.instance.client
    .from('team_members')
    .select('teams(*)')
    .eq('user_id', userId);
  return res.map((e) => Team.fromJson(e['teams'])).toList();
});
```

---

## 12. CHECKLIST SEBELUM SUBMIT

- [ ] Login & Register berfungsi tanpa OTP
- [ ] Dashboard tampil daftar tim user
- [ ] Bisa buat tim baru via side popup
- [ ] Bisa lihat detail tim via side popup
- [ ] Profile page tampil info user
- [ ] Bisa edit profil via side popup
- [ ] **Mobile**: Push notification muncul saat tim baru dibuat (FCM token tersimpan, notif terkirim)
- [ ] **Web**: PWA manifest ada, app bisa di-install dari Chrome
- [ ] Web layout pakai NavigationRail (desktop sidebar)
- [ ] Mobile layout pakai BottomNavigationBar
- [ ] Commit history jelas di Git (minimal: init, feat: auth, feat: dashboard, feat: profile, feat: biometric, feat: pwa)
- [ ] RLS Supabase aktif

---

## 13. DOKUMEN TEKNIS (Untuk Laporan)

### Deskripsi Aplikasi
SyncTeam adalah aplikasi manajemen tim lintas platform yang memungkinkan pengguna untuk bergabung dan mengelola tim secara kolaboratif. Dikembangkan untuk memenuhi kebutuhan koordinasi tim yang sederhana namun efektif, dengan fokus pada kemudahan penggunaan dan aksesibilitas di berbagai perangkat.

### Arsitektur Sistem
- **Client Layer**: Flutter Web (desktop PWA) + Flutter Mobile (Android/iOS)
- **Backend Layer**: Supabase (BaaS) — PostgreSQL + Auth + Storage
- **Communication**: HTTPS REST via Supabase Dart Client
- **State**: Riverpod (reactive state management)

### Teknologi & Alasan
| Teknologi | Alasan |
|---|---|
| Flutter | Satu codebase untuk web + mobile, UI bisa dikustomisasi per platform |
| Supabase | Backend siap pakai, auth built-in, PostgreSQL, free tier, realtime support |
| Riverpod | State management yang type-safe dan testable |
| GoRouter | Routing deklaratif, support deep link |
| local_auth | Biometric authentication untuk mobile (platform-specific) |

### Platform-Specific Features
1. **Mobile — Push Notification (FCM)**: Menggunakan Firebase Cloud Messaging untuk mengirim push notification ke perangkat Android/iOS saat tim baru dibuat. Notifikasi muncul di system notification tray meski app sedang di-background atau tertutup. Fitur ini memanfaatkan kemampuan native notification OS yang tidak dapat direplikasi identik di web dalam proyek ini.
2. **Web — PWA (Progressive Web App)**: Aplikasi web dapat di-install langsung ke desktop/laptop via browser (Chrome, Edge). Dengan service worker, halaman dashboard tetap dapat diakses saat offline menggunakan data cache. Fitur ini spesifik untuk platform web karena mobile app sudah native.

### Pembagian Tugas Tim
> Sesuaikan dengan anggota tim kamu:
- **[Nama 1]**: Setup Supabase, database schema, auth flow
- **[Nama 2]**: Flutter mobile UI (dashboard, profile, bottom sheets)
- **[Nama 3]**: Flutter web UI (desktop layout, side panels, PWA setup)
- **[Nama 4]**: Biometric feature, state management (Riverpod providers)

---

## 14. INSTRUKSI UNTUK AI CODER

Jika kamu adalah AI yang diminta untuk mengimplementasikan proyek ini, ikuti urutan berikut:

### Urutan Implementasi
1. **Setup project** — `flutter create syncteam`, tambah dependencies di pubspec.yaml
2. **Supabase setup** — Jalankan SQL schema di atas di Supabase SQL Editor. Disable email confirmation di Auth settings.
3. **Core** — `supabase_client.dart`, `theme.dart`, `router.dart`
4. **Auth feature** — `auth_screen.dart` dengan 2 tab (login/register), connect ke Supabase
5. **Models** — `team.dart`, `profile.dart` (fromJson/toJson)
6. **Providers** — auth provider, teams provider, profile provider
7. **Dashboard** — Web version dulu (GridView + NavigationRail), lalu Mobile version (ListView + BottomNav)
8. **Side panels** — `SidePanel` widget, team detail, create team, edit profile
9. **Profile screen** — tampil info, tombol edit → buka panel
10. **Push Notification** — Setup Firebase, `FcmService`, simpan token ke Supabase, trigger notif saat buat tim
11. **PWA** — Update `web/manifest.json`, test install di Chrome
12. **Polish** — Animasi side panel, loading states, error handling

### Rules Penting
- Gunakan `kIsWeb` untuk bedakan logika web vs mobile
- FCM dan Firebase hanya diinisialisasi kalau `!kIsWeb` (gunakan `kIsWeb` check)
- Simpan FCM token ke tabel `profiles` setelah login berhasil di mobile
- Side panel di web = `AnimatedPositioned` overlay dari kanan
- Side panel di mobile = `showModalBottomSheet`
- Jangan buat halaman baru untuk form (semua lewat panel/sheet)
- Gunakan `Stack` di DashboardScreen untuk overlay side panel di web

### Environment Variables
Buat file `.env` atau langsung hardcode sementara di `supabase_client.dart`:
```dart
const supabaseUrl = 'https://XXXX.supabase.co';
const supabaseAnonKey = 'eyJXXXX...';
```
> Ganti XXXX dengan credentials dari Supabase project kamu.
