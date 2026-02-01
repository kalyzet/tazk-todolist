// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Manajer Tugas Akademik';

  @override
  String get semester => 'Semester';

  @override
  String get uts => 'UTS';

  @override
  String get uas => 'UAS';

  @override
  String get tugas => 'Tugas';

  @override
  String get progres => 'Progres';

  @override
  String get deadline => 'Batas Waktu';

  @override
  String get mataKuliah => 'Mata Kuliah';

  @override
  String get dosen => 'Dosen';

  @override
  String get setupTitle => 'Pengaturan Awal';

  @override
  String get setupSubtitle => 'Pilih semester dan periode untuk memulai';

  @override
  String get selectSemester => 'Pilih Semester';

  @override
  String get selectPeriod => 'Pilih Periode';

  @override
  String get utsLong => 'Ujian Tengah Semester';

  @override
  String get uasLong => 'Ujian Akhir Semester';

  @override
  String get continueButton => 'Lanjutkan';

  @override
  String get pleaseSelectSemester => 'Silakan pilih semester';

  @override
  String get pleaseSelectPeriod => 'Silakan pilih periode';

  @override
  String get taskList => 'Daftar Tugas';

  @override
  String get addTask => 'Tambah Tugas';

  @override
  String get sortBy => 'Urutkan berdasarkan';

  @override
  String get noTasks => 'Belum ada tugas';

  @override
  String get noTasksSubtitle => 'Tekan tombol + untuk menambah tugas baru';

  @override
  String remainingDays(int count) {
    return '$count hari tersisa';
  }

  @override
  String get overdue => 'Terlambat';

  @override
  String get completed => 'Selesai';

  @override
  String get settings => 'Pengaturan';

  @override
  String get notifications => 'Notifikasi';

  @override
  String get enableNotifications => 'Aktifkan Notifikasi';

  @override
  String get notificationDescription =>
      'Terima pengingat untuk tugas yang mendekati deadline';

  @override
  String get backup => 'Cadangan';

  @override
  String get exportData => 'Ekspor Data';

  @override
  String get importData => 'Impor Data';

  @override
  String get exportDescription => 'Simpan semua tugas ke file JSON';

  @override
  String get importDescription => 'Muat tugas dari file JSON';

  @override
  String get about => 'Tentang';

  @override
  String get appVersion => 'Versi Aplikasi';

  @override
  String get developer => 'Pengembang';

  @override
  String get exportSuccess => 'Data berhasil diekspor';

  @override
  String get exportError => 'Gagal mengekspor data';

  @override
  String exportLocationInfo(String fileName) {
    return 'File backup tersimpan di folder Download dengan nama: $fileName';
  }

  @override
  String get storagePermissionRequired =>
      'Izin akses penyimpanan diperlukan untuk ekspor data';

  @override
  String importSuccess(int count) {
    return 'Berhasil mengimpor $count tugas';
  }

  @override
  String get importError => 'Gagal mengimpor data';

  @override
  String get selectFile => 'Pilih File';

  @override
  String get cancel => 'Batal';

  @override
  String get addNewTask => 'Tambah Tugas Baru';

  @override
  String get taskName => 'Nama Tugas';

  @override
  String get taskNameHint => 'Masukkan nama tugas';

  @override
  String get courseName => 'Mata Kuliah';

  @override
  String get courseNameHint => 'Masukkan nama mata kuliah';

  @override
  String get instructorName => 'Nama Dosen';

  @override
  String get instructorNameHint => 'Masukkan nama dosen';

  @override
  String get selectDeadline => 'Pilih Batas Waktu';

  @override
  String get selectDeadlineHint => 'Pilih batas waktu tugas';

  @override
  String get selectSemesterHint => 'Pilih semester';

  @override
  String get selectPeriodHint => 'Pilih periode';

  @override
  String get taskNameRequired => 'Nama tugas tidak boleh kosong';

  @override
  String get taskNameMinLength => 'Nama tugas minimal 3 karakter';

  @override
  String get courseNameRequired => 'Mata kuliah tidak boleh kosong';

  @override
  String get courseNameMinLength => 'Mata kuliah minimal 2 karakter';

  @override
  String get instructorNameRequired => 'Nama dosen tidak boleh kosong';

  @override
  String get instructorNameMinLength => 'Nama dosen minimal 2 karakter';

  @override
  String get deadlineRequired => 'Silakan pilih batas waktu tugas';

  @override
  String get semesterRequired => 'Silakan pilih semester';

  @override
  String get periodRequired => 'Silakan pilih periode';

  @override
  String get taskAddedSuccess => 'Tugas berhasil ditambahkan';

  @override
  String get taskAddedError => 'Gagal menambahkan tugas';

  @override
  String get editTask => 'Edit Tugas';

  @override
  String get deleteTask => 'Hapus Tugas';

  @override
  String deleteTaskConfirm(String taskName) {
    return 'Apakah Anda yakin ingin menghapus tugas \"$taskName\"?\n\nTindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get delete => 'Hapus';

  @override
  String get taskDeletedSuccess => 'Tugas berhasil dihapus';

  @override
  String get taskDeletedError => 'Gagal menghapus tugas';

  @override
  String get taskUpdatedSuccess => 'Tugas berhasil diperbarui';

  @override
  String get taskUpdatedError => 'Gagal memperbarui tugas';

  @override
  String get updateTask => 'Perbarui Tugas';

  @override
  String get taskProgress => 'Progres Tugas';

  @override
  String get progressRangeError => 'Progres harus antara 0-100%';

  @override
  String get notStarted => 'Belum Dimulai';

  @override
  String get justStarted => 'Baru Dimulai';

  @override
  String get inProgress => 'Dalam Progres';

  @override
  String get halfWay => 'Setengah Jalan';

  @override
  String get almostDone => 'Hampir Selesai';

  @override
  String get progressUpdateInfo =>
      'Perubahan pada deadline atau progres akan memperbarui notifikasi secara otomatis.';

  @override
  String get newTaskInfo =>
      'Tugas baru akan dimulai dengan progres 0% dan dapat diperbarui nanti.';

  @override
  String get switchContext => 'Ganti Context';

  @override
  String get selectAcademicContext => 'Pilih Context Akademik';

  @override
  String get contextSwitchError => 'Gagal mengganti context';

  @override
  String get chooseAcademicContext => 'Pilih Context Akademik';

  @override
  String get chooseContextSubtitle =>
      'Pilih semester dan periode untuk memulai';

  @override
  String get chooseContext => 'Pilih Context';

  @override
  String get tryAgain => 'Coba Lagi';

  @override
  String get taskSummary => 'Ringkasan Tugas';

  @override
  String get total => 'Total';

  @override
  String get urgent => 'Segera';

  @override
  String get today => 'Hari ini';

  @override
  String get tomorrow => 'Besok';

  @override
  String daysRemaining(int count) {
    return '$count hari lagi';
  }

  @override
  String overdueByDays(int count) {
    return 'Terlambat $count hari';
  }

  @override
  String get overdueByDay => 'Terlambat 1 hari';

  @override
  String get sortByDeadline => 'Batas Waktu';

  @override
  String get sortByProgress => 'Progres';

  @override
  String get sortByCourseName => 'Mata Kuliah';

  @override
  String get sortByTaskName => 'Nama Tugas';

  @override
  String get sortByDeadlineDesc =>
      'Urutkan berdasarkan batas waktu (terdini ke terakhir)';

  @override
  String get sortByProgressDesc =>
      'Urutkan berdasarkan progres (terendah ke tertinggi)';

  @override
  String get sortByCourseNameDesc =>
      'Urutkan berdasarkan nama mata kuliah (A-Z)';

  @override
  String get sortByTaskNameDesc => 'Urutkan berdasarkan nama tugas (A-Z)';

  @override
  String get appDescription => 'Aplikasi manajemen tugas untuk mahasiswa';

  @override
  String get developerTeam => 'Kalyzet Team';

  @override
  String get notificationSaveError => 'Gagal menyimpan pengaturan notifikasi';

  @override
  String get pickDeadlineTime => 'Pilih Waktu Deadline';

  @override
  String get pickDeadlineDate => 'Pilih Batas Waktu';

  @override
  String get hour => 'Jam';

  @override
  String get minute => 'Menit';

  @override
  String get dateFieldLabel => 'Tanggal Deadline';

  @override
  String get dateFieldHint => 'dd/mm/yyyy';

  @override
  String get invalidDateFormat => 'Format tanggal tidak valid';

  @override
  String get invalidDate => 'Tanggal tidak valid';

  @override
  String get choose => 'Pilih';
}
