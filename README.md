# Tazk

Aplikasi ini merupakan aplikasi mobile berbasis **Flutter** yang dirancang untuk membantu mahasiswa dalam mengelola tugas perkuliahan secara terstruktur, kontekstual, dan efisien. Aplikasi menggunakan pendekatan **progress-based task management** dengan pengelompokan berdasarkan **semester** dan **periode akademik (UTS dan UAS)**.

---

## 🎯 Tujuan Aplikasi

Tujuan utama aplikasi ini adalah:

- Membantu mahasiswa mengatur tugas kuliah agar tidak terlewat deadline
- Menyediakan pemantauan progres tugas secara bertahap (0–100%)
- Menyajikan tugas sesuai konteks akademik (semester dan periode UTS/UAS)
- Mempermudah akses tugas terakhir yang sedang dikerjakan

---

## ✨ Fitur Utama

- **Manajemen Tugas**
    - Tambah, ubah, dan hapus tugas
    - Informasi tugas meliputi nama tugas, mata kuliah, dosen, deadline, dan catatan
- **Progress Berbasis Persentase**
    - Progres tugas dinyatakan dalam bentuk 0–100%
    - Tugas otomatis dianggap selesai ketika progres mencapai 100%
- **Pengelompokan Akademik**
    - Tugas dikelompokkan berdasarkan semester
    - Setiap semester dibagi menjadi periode:
        - Pre-UTS
        - Pre-UAS
- **Deadline Awareness**
    - Menampilkan sisa hari menuju deadline
    - Memberi indikasi tugas yang sudah melewati tenggat waktu
- **Smart Navigation**
    - Aplikasi mengingat konteks terakhir (semester dan periode)
    - Pengguna langsung diarahkan ke daftar tugas terakhir saat membuka aplikasi

---

## 🧭 Alur Penggunaan Aplikasi

1. **Pengguna Baru**
    - Masuk aplikasi
    - Memilih semester
    - Memilih periode (UTS / UAS)
    - Melihat daftar tugas (kosong) dan mulai menambahkan tugas

2. **Pengguna Lama**
    - Masuk aplikasi
    - Langsung diarahkan ke daftar tugas dari semester dan periode terakhir yang digunakan

---

## 🗂️ Struktur Data Tugas

Setiap tugas memiliki atribut berikut:

- Nama tugas
- Mata kuliah
- Nama dosen
- Progres (0–100%)
- Deadline
- Semester
- Periode akademik (UTS / UAS)
- Catatan tambahan (opsional)

---

## 🛠️ Teknologi yang Digunakan

- **Framework**: Flutter
- **Bahasa Pemrograman**: Dart
- **Database Lokal**: SQLite (sqflite)
- **State Management**: Provider
- **Local Preference**: SharedPreferences

---

## 🏗️ Arsitektur Aplikasi

Aplikasi menerapkan pemisahan tanggung jawab yang jelas:

- **UI Layer**: Menangani tampilan dan interaksi pengguna
- **Logic & State Layer**: Mengelola state aplikasi dan logika bisnis
- **Data Layer**: Mengelola penyimpanan dan pengambilan data dari SQLite

Pendekatan ini bertujuan menjaga kestabilan sistem serta memudahkan pengembangan lanjutan.

---

## 📁 Struktur Folder

```

lib/
├─ models/
│   └─ task.dart
├─ services/
│   └─ database_helper.dart
├─ providers/
│   └─ task_provider.dart
├─ screens/
│   ├─ initial_screen.dart
│   ├─ semester_picker_screen.dart
│   ├─ era_picker_screen.dart
│   └─ task_list_screen.dart
└─ widgets/

```

---

## 🚀 Pengembangan Selanjutnya (Opsional)

- Notifikasi pengingat deadline
- Statistik progres tugas per semester
- Dark mode
- Backup dan restore data

---

## 📌 Catatan

Aplikasi ini dirancang dengan konsep **offline-first** sehingga dapat digunakan tanpa koneksi internet dan fokus pada kestabilan serta kebutuhan nyata mahasiswa dalam keseharian.

---

## 👨‍🎓 Target Pengguna

Mahasiswa yang ingin mengelola tugas perkuliahan secara terstruktur, praktis, dan sesuai dengan alur akademik.

```

```
