# REFACTOR - Tazk Bug Fixes & Improvements

## Status Legend

- `[ ]` = Belum dikerjakan
- `[x]` = Selesai

---

## 🔴 CRITICAL — Fix Sistem Notifikasi

- [x] **[1] Tambah package `timezone` ke `pubspec.yaml`**
  - File: `pubspec.yaml`
  - Tambah `timezone: ^0.9.4` ke dependencies section

- [x] **[2] Fix `_convertToTZDateTime` di `notification_service.dart`**
  - File: `lib/services/notification_service.dart:156-161`
  - Import `timezone` package (`TZDateTime` + timezone database)
  - Inisialisasi timezone database di `initialize()`
  - Implementasi proper conversion ke `TZDateTime` menggunakan `tz.local`

- [x] **[3] Panggil `NotificationService.initialize()` saat app startup**
  - File: `lib/main.dart:109-110`
  - Tambah `await NotificationService().initialize();` di `_AppInitializerState._initializeApp()`

- [x] **[4] Integrasi NotificationService di `task_service.dart`**
  - File: `lib/services/task_service.dart`
  - `createTask()`: panggil `scheduleTaskNotifications()` setelah insert DB
  - `updateTask()`: panggil `rescheduleTaskNotifications()` setelah update DB
  - `deleteTask()`: panggil `cancelTaskNotifications()` sebelum delete DB

---

## 🟡 MODERATE — Bug & Konsistensi

- [x] **[5] Fix export path di `settings_screen.dart`**
  - File: `lib/ui/screens/settings_screen.dart`
  - Gunakan `getApplicationDocumentsDirectory()` secara konsisten
  - Hapus pesan misleading tentang "folder Download"

- [x] **[6] Refactor `settings_screen.dart` ke Provider pattern**
  - File: `lib/ui/screens/settings_screen.dart`
  - Hapus direct instantiation, gunakan singleton instances

- [x] **[7] Ganti hardcoded strings di `task_editing_screen.dart` ke AppLocalizations**
  - File: `lib/ui/screens/task_editing_screen.dart`
  - ~20+ string hardcoded diganti ke l10n calls
  - Juga fix `task_creation_screen.dart` (semester/period dialogs, form labels)

- [x] **[8] Hapus excessive `debugPrint` di `settings_screen.dart`**
  - File: `lib/ui/screens/settings_screen.dart`
  - Hapus ~15+ panggilan `debugPrint` di method `_exportData()`

- [x] **[9] Hapus dead code di `task_service.dart`**
  - File: `lib/services/task_service.dart:42-45`
  - Hapus validasi `validateProgressRange()` yang selalu pass

- [x] **[10] Hapus dead code `_semesterController` di `initial_setup_screen.dart`**
  - File: `lib/ui/screens/initial_setup_screen.dart:25`
  - Hapus `TextEditingController` yang tidak dipakai

---

## 📝 ARB Keys Baru

- [x] **[11] Tambah key ARB untuk task_editing_screen.dart**
  - File: `lib/l10n/app_id.arb`
  - Tambah: `selectSemesterTitle`, `selectPeriodTitle`, `semesterLabel`, `periodLabel`, `deadlineLabel`

---

## Verifikasi

- [x] **[12] Jalankan `flutter analyze`** — Tidak ada error baru dari perubahan
- [x] **[13] Jalankan `flutter test`** — 99/99 tests passed
