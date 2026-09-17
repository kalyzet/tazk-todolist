# REFACTOR - Tazk Bug Fixes & Improvements

## Status Legend

- `[ ]` = Belum dikerjakan
- `[x]` = Selesai

---

## 🔴 CRITICAL — Fix Sistem Notifikasi

- [ ] **[1] Tambah package `timezone` ke `pubspec.yaml`**
  - File: `pubspec.yaml`
  - Tambah `timezone: ^0.9.4` ke dependencies section

- [ ] **[2] Fix `_convertToTZDateTime` di `notification_service.dart`**
  - File: `lib/services/notification_service.dart:156-161`
  - Ubah return type dari `dynamic` ke `TZDateTime`
  - Import package `timezone` dan `timezone/data/latest_all.dart`
  - Inisialisasi timezone database (`TZDatabase`) di `initialize()`
  - Implementasi conversion: `TZDateTime(local, dateTime.year, dateTime.month, ...)`

- [ ] **[3] Panggil `NotificationService.initialize()` saat app startup**
  - File: `lib/main.dart:109-110`
  - Tambah `await NotificationService().initialize();` di `_AppInitializerState._initializeApp()` setelah `taskProvider.initialize()`

- [ ] **[4] Integrasi NotificationService di `task_service.dart`**
  - File: `lib/services/task_service.dart:93-95, 112`
  - Import `NotificationService`
  - Di `updateTask()`: panggil `NotificationService().rescheduleTaskNotifications(updatedTask)` setelah update DB
  - Di `deleteTask()`: panggil `NotificationService().cancelTaskNotifications(taskId)` sebelum delete DB

---

## 🟡 MODERATE — Bug & Konsistensi

- [ ] **[5] Fix export path di `settings_screen.dart`**
  - File: `lib/ui/screens/settings_screen.dart:110-144`
  - Perbaiki `locationMessage` agar akurat (bukan "folder Download" kalau sebenarnya ke folder internal app)
  - Pertimbangkan gunakan MediaStore API untuk Android 10+ jika memungkinkan

- [ ] **[6] Refactor `settings_screen.dart` ke Provider pattern**
  - File: `lib/ui/screens/settings_screen.dart:28-30`
  - Hapus direct instantiation: `BackupService()`, `NotificationService()`, `PreferencesRepository()`
  - Retrieve via Provider atau inject melalui constructor agar konsisten dengan pattern di tempat lain

- [ ] **[7] Ganti hardcoded strings di `task_editing_screen.dart` ke AppLocalizations**
  - File: `lib/ui/screens/task_editing_screen.dart`
  - ~20+ string hardcoded Indonesia yang perlu diganti ke l10n calls
  - Contoh: `'Pilih Batas Waktu'` → `l10n.selectDeadline`, `'Batal'` → `l10n.cancel`, dll.

- [ ] **[8] Hapus excessive `debugPrint` di `settings_screen.dart`**
  - File: `lib/ui/screens/settings_screen.dart:98-157`
  - Hapus ~15+ panggilan `debugPrint` di method `_exportData()`

- [ ] **[9] Hapus dead code di `task_service.dart`**
  - File: `lib/services/task_service.dart:42-45`
  - Hapus validasi `validateProgressRange()` yang selalu pass setelah force `progress: 0`

- [ ] **[10] Hapus dead code `_semesterController` di `initial_setup_screen.dart`**
  - File: `lib/ui/screens/initial_setup_screen.dart:25`
  - `TextEditingController` yang dibuat tapi tidak pernah dipakai

---

## 📝 ARB Keys Baru

- [ ] **[11] Tambah key ARB yang diperlukan untuk `task_editing_screen.dart`**
  - File: `lib/l10n/app_id.arb`
  - Pastikan semua string yang di-hardcode di editing screen punya key ARB
  - Beberapa key sudah ada (seperti `editTask`, `deleteTask`, `cancel`, dll.) tinggal connect ke code

---

## Verifikasi

- [ ] **[12] Jalankan `flutter analyze` untuk pastikan tidak ada error**
- [ ] **[13] Jalankan `flutter test` untuk pastikan test existing masih pass**
