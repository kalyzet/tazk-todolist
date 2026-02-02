import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('id')];

  /// The title of the application
  ///
  /// In id, this message translates to:
  /// **'Tazk'**
  String get appTitle;

  /// Academic semester
  ///
  /// In id, this message translates to:
  /// **'Semester'**
  String get semester;

  /// Ujian Tengah Semester (Midterm Exam)
  ///
  /// In id, this message translates to:
  /// **'UTS'**
  String get uts;

  /// Ujian Akhir Semester (Final Exam)
  ///
  /// In id, this message translates to:
  /// **'UAS'**
  String get uas;

  /// Task or assignment
  ///
  /// In id, this message translates to:
  /// **'Tugas'**
  String get tugas;

  /// Progress
  ///
  /// In id, this message translates to:
  /// **'Progres'**
  String get progres;

  /// Deadline
  ///
  /// In id, this message translates to:
  /// **'Batas Waktu'**
  String get deadline;

  /// Course or subject
  ///
  /// In id, this message translates to:
  /// **'Mata Kuliah'**
  String get mataKuliah;

  /// Instructor or lecturer
  ///
  /// In id, this message translates to:
  /// **'Dosen'**
  String get dosen;

  /// Initial setup title
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Awal'**
  String get setupTitle;

  /// Initial setup subtitle
  ///
  /// In id, this message translates to:
  /// **'Pilih semester dan periode untuk memulai'**
  String get setupSubtitle;

  /// Select semester prompt
  ///
  /// In id, this message translates to:
  /// **'Pilih Semester'**
  String get selectSemester;

  /// Select period prompt
  ///
  /// In id, this message translates to:
  /// **'Pilih Periode'**
  String get selectPeriod;

  /// Full name for UTS
  ///
  /// In id, this message translates to:
  /// **'Ujian Tengah Semester'**
  String get utsLong;

  /// Full name for UAS
  ///
  /// In id, this message translates to:
  /// **'Ujian Akhir Semester'**
  String get uasLong;

  /// Continue button
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan'**
  String get continueButton;

  /// Please select semester error
  ///
  /// In id, this message translates to:
  /// **'Silakan pilih semester'**
  String get pleaseSelectSemester;

  /// Please select period error
  ///
  /// In id, this message translates to:
  /// **'Silakan pilih periode'**
  String get pleaseSelectPeriod;

  /// Task list title
  ///
  /// In id, this message translates to:
  /// **'Daftar Tugas'**
  String get taskList;

  /// Add task button
  ///
  /// In id, this message translates to:
  /// **'Tambah Tugas'**
  String get addTask;

  /// Sort by label
  ///
  /// In id, this message translates to:
  /// **'Urutkan berdasarkan'**
  String get sortBy;

  /// No tasks message
  ///
  /// In id, this message translates to:
  /// **'Belum ada tugas'**
  String get noTasks;

  /// No tasks subtitle
  ///
  /// In id, this message translates to:
  /// **'Tekan tombol + untuk menambah tugas baru'**
  String get noTasksSubtitle;

  /// Remaining days
  ///
  /// In id, this message translates to:
  /// **'{count} hari tersisa'**
  String remainingDays(int count);

  /// Overdue indicator
  ///
  /// In id, this message translates to:
  /// **'Terlambat'**
  String get overdue;

  /// Completed status
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get completed;

  /// Settings
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// Notifications
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get notifications;

  /// Enable notifications
  ///
  /// In id, this message translates to:
  /// **'Aktifkan Notifikasi'**
  String get enableNotifications;

  /// Notification description
  ///
  /// In id, this message translates to:
  /// **'Terima pengingat untuk tugas yang mendekati deadline'**
  String get notificationDescription;

  /// Backup
  ///
  /// In id, this message translates to:
  /// **'Cadangan'**
  String get backup;

  /// Export data
  ///
  /// In id, this message translates to:
  /// **'Ekspor Data'**
  String get exportData;

  /// Import data
  ///
  /// In id, this message translates to:
  /// **'Impor Data'**
  String get importData;

  /// Export description
  ///
  /// In id, this message translates to:
  /// **'Simpan semua tugas ke file JSON'**
  String get exportDescription;

  /// Import description
  ///
  /// In id, this message translates to:
  /// **'Muat tugas dari file JSON'**
  String get importDescription;

  /// About
  ///
  /// In id, this message translates to:
  /// **'Tentang'**
  String get about;

  /// App version
  ///
  /// In id, this message translates to:
  /// **'Versi Aplikasi'**
  String get appVersion;

  /// Developer
  ///
  /// In id, this message translates to:
  /// **'Pengembang'**
  String get developer;

  /// Export success message
  ///
  /// In id, this message translates to:
  /// **'Data berhasil diekspor'**
  String get exportSuccess;

  /// Export error message
  ///
  /// In id, this message translates to:
  /// **'Gagal mengekspor data'**
  String get exportError;

  /// Export location info message
  ///
  /// In id, this message translates to:
  /// **'File backup tersimpan di folder Download dengan nama: {fileName}'**
  String exportLocationInfo(String fileName);

  /// Storage permission required message
  ///
  /// In id, this message translates to:
  /// **'Izin akses penyimpanan diperlukan untuk ekspor data'**
  String get storagePermissionRequired;

  /// Export cancelled message
  ///
  /// In id, this message translates to:
  /// **'Ekspor dibatalkan'**
  String get exportCancelled;

  /// Save backup file dialog title
  ///
  /// In id, this message translates to:
  /// **'Simpan file backup'**
  String get saveBackupFile;

  /// Import success message
  ///
  /// In id, this message translates to:
  /// **'Berhasil mengimpor {count} tugas'**
  String importSuccess(int count);

  /// Import error message
  ///
  /// In id, this message translates to:
  /// **'Gagal mengimpor data'**
  String get importError;

  /// Select file
  ///
  /// In id, this message translates to:
  /// **'Pilih File'**
  String get selectFile;

  /// Cancel
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// Add new task title
  ///
  /// In id, this message translates to:
  /// **'Tambah Tugas Baru'**
  String get addNewTask;

  /// Task name field
  ///
  /// In id, this message translates to:
  /// **'Nama Tugas'**
  String get taskName;

  /// Task name hint
  ///
  /// In id, this message translates to:
  /// **'Masukkan nama tugas'**
  String get taskNameHint;

  /// Course name field
  ///
  /// In id, this message translates to:
  /// **'Mata Kuliah'**
  String get courseName;

  /// Course name hint
  ///
  /// In id, this message translates to:
  /// **'Masukkan nama mata kuliah'**
  String get courseNameHint;

  /// Instructor name field
  ///
  /// In id, this message translates to:
  /// **'Nama Dosen'**
  String get instructorName;

  /// Instructor name hint
  ///
  /// In id, this message translates to:
  /// **'Masukkan nama dosen'**
  String get instructorNameHint;

  /// Select deadline prompt
  ///
  /// In id, this message translates to:
  /// **'Pilih Batas Waktu'**
  String get selectDeadline;

  /// Select deadline hint
  ///
  /// In id, this message translates to:
  /// **'Pilih batas waktu tugas'**
  String get selectDeadlineHint;

  /// Select semester hint
  ///
  /// In id, this message translates to:
  /// **'Pilih semester'**
  String get selectSemesterHint;

  /// Select period hint
  ///
  /// In id, this message translates to:
  /// **'Pilih periode'**
  String get selectPeriodHint;

  /// Task name required error
  ///
  /// In id, this message translates to:
  /// **'Nama tugas tidak boleh kosong'**
  String get taskNameRequired;

  /// Task name minimum length error
  ///
  /// In id, this message translates to:
  /// **'Nama tugas minimal 3 karakter'**
  String get taskNameMinLength;

  /// Course name required error
  ///
  /// In id, this message translates to:
  /// **'Mata kuliah tidak boleh kosong'**
  String get courseNameRequired;

  /// Course name minimum length error
  ///
  /// In id, this message translates to:
  /// **'Mata kuliah minimal 2 karakter'**
  String get courseNameMinLength;

  /// Instructor name required error
  ///
  /// In id, this message translates to:
  /// **'Nama dosen tidak boleh kosong'**
  String get instructorNameRequired;

  /// Instructor name minimum length error
  ///
  /// In id, this message translates to:
  /// **'Nama dosen minimal 2 karakter'**
  String get instructorNameMinLength;

  /// Deadline required error
  ///
  /// In id, this message translates to:
  /// **'Silakan pilih batas waktu tugas'**
  String get deadlineRequired;

  /// Semester required error
  ///
  /// In id, this message translates to:
  /// **'Silakan pilih semester'**
  String get semesterRequired;

  /// Period required error
  ///
  /// In id, this message translates to:
  /// **'Silakan pilih periode'**
  String get periodRequired;

  /// Task added success message
  ///
  /// In id, this message translates to:
  /// **'Tugas berhasil ditambahkan'**
  String get taskAddedSuccess;

  /// Task added error message
  ///
  /// In id, this message translates to:
  /// **'Gagal menambahkan tugas'**
  String get taskAddedError;

  /// Edit task title
  ///
  /// In id, this message translates to:
  /// **'Edit Tugas'**
  String get editTask;

  /// Delete task title
  ///
  /// In id, this message translates to:
  /// **'Hapus Tugas'**
  String get deleteTask;

  /// Delete task confirmation message
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin menghapus tugas \"{taskName}\"?\n\nTindakan ini tidak dapat dibatalkan.'**
  String deleteTaskConfirm(String taskName);

  /// Delete button
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get delete;

  /// Task deleted success message
  ///
  /// In id, this message translates to:
  /// **'Tugas berhasil dihapus'**
  String get taskDeletedSuccess;

  /// Task deleted error message
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus tugas'**
  String get taskDeletedError;

  /// Task updated success message
  ///
  /// In id, this message translates to:
  /// **'Tugas berhasil diperbarui'**
  String get taskUpdatedSuccess;

  /// Task updated error message
  ///
  /// In id, this message translates to:
  /// **'Gagal memperbarui tugas'**
  String get taskUpdatedError;

  /// Update task button
  ///
  /// In id, this message translates to:
  /// **'Perbarui Tugas'**
  String get updateTask;

  /// Task progress label
  ///
  /// In id, this message translates to:
  /// **'Progres Tugas'**
  String get taskProgress;

  /// Progress range error
  ///
  /// In id, this message translates to:
  /// **'Progres harus antara 0-100%'**
  String get progressRangeError;

  /// Not started status
  ///
  /// In id, this message translates to:
  /// **'Belum Dimulai'**
  String get notStarted;

  /// Just started status
  ///
  /// In id, this message translates to:
  /// **'Baru Dimulai'**
  String get justStarted;

  /// In progress status
  ///
  /// In id, this message translates to:
  /// **'Dalam Progres'**
  String get inProgress;

  /// Half way status
  ///
  /// In id, this message translates to:
  /// **'Setengah Jalan'**
  String get halfWay;

  /// Almost done status
  ///
  /// In id, this message translates to:
  /// **'Hampir Selesai'**
  String get almostDone;

  /// Progress update info message
  ///
  /// In id, this message translates to:
  /// **'Perubahan pada deadline atau progres akan memperbarui notifikasi secara otomatis.'**
  String get progressUpdateInfo;

  /// New task info message
  ///
  /// In id, this message translates to:
  /// **'Tugas baru akan dimulai dengan progres 0% dan dapat diperbarui nanti.'**
  String get newTaskInfo;

  /// Switch context tooltip
  ///
  /// In id, this message translates to:
  /// **'Ganti Konteks'**
  String get switchContext;

  /// Select academic context title
  ///
  /// In id, this message translates to:
  /// **'Pilih Konteks Akademik'**
  String get selectAcademicContext;

  /// Context switch error message
  ///
  /// In id, this message translates to:
  /// **'Gagal mengganti konteks'**
  String get contextSwitchError;

  /// Choose academic context message
  ///
  /// In id, this message translates to:
  /// **'Pilih Konteks Akademik'**
  String get chooseAcademicContext;

  /// Choose context subtitle
  ///
  /// In id, this message translates to:
  /// **'Pilih semester dan periode untuk memulai'**
  String get chooseContextSubtitle;

  /// Choose context button
  ///
  /// In id, this message translates to:
  /// **'Pilih Konteks'**
  String get chooseContext;

  /// Try again button
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get tryAgain;

  /// Task summary header
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Tugas'**
  String get taskSummary;

  /// Total label
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get total;

  /// Urgent label
  ///
  /// In id, this message translates to:
  /// **'Segera'**
  String get urgent;

  /// Today label
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get today;

  /// Tomorrow label
  ///
  /// In id, this message translates to:
  /// **'Besok'**
  String get tomorrow;

  /// Days remaining format
  ///
  /// In id, this message translates to:
  /// **'{count} hari lagi'**
  String daysRemaining(int count);

  /// Overdue by days format
  ///
  /// In id, this message translates to:
  /// **'Terlambat {count} hari'**
  String overdueByDays(int count);

  /// Overdue by one day
  ///
  /// In id, this message translates to:
  /// **'Terlambat 1 hari'**
  String get overdueByDay;

  /// Sort by deadline
  ///
  /// In id, this message translates to:
  /// **'Batas Waktu'**
  String get sortByDeadline;

  /// Sort by progress
  ///
  /// In id, this message translates to:
  /// **'Progres'**
  String get sortByProgress;

  /// Sort by course name
  ///
  /// In id, this message translates to:
  /// **'Mata Kuliah'**
  String get sortByCourseName;

  /// Sort by task name
  ///
  /// In id, this message translates to:
  /// **'Nama Tugas'**
  String get sortByTaskName;

  /// Sort by deadline description
  ///
  /// In id, this message translates to:
  /// **'Urutkan berdasarkan batas waktu (terdini ke terakhir)'**
  String get sortByDeadlineDesc;

  /// Sort by progress description
  ///
  /// In id, this message translates to:
  /// **'Urutkan berdasarkan progres (terendah ke tertinggi)'**
  String get sortByProgressDesc;

  /// Sort by course name description
  ///
  /// In id, this message translates to:
  /// **'Urutkan berdasarkan nama mata kuliah (A-Z)'**
  String get sortByCourseNameDesc;

  /// Sort by task name description
  ///
  /// In id, this message translates to:
  /// **'Urutkan berdasarkan nama tugas (A-Z)'**
  String get sortByTaskNameDesc;

  /// App description
  ///
  /// In id, this message translates to:
  /// **'Aplikasi manajemen tugas untuk mahasiswa'**
  String get appDescription;

  /// Developer team name
  ///
  /// In id, this message translates to:
  /// **'Kalyzet Team'**
  String get developerTeam;

  /// Notification save error
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan pengaturan notifikasi'**
  String get notificationSaveError;

  /// Pick deadline time
  ///
  /// In id, this message translates to:
  /// **'Pilih Waktu Deadline'**
  String get pickDeadlineTime;

  /// Pick deadline date
  ///
  /// In id, this message translates to:
  /// **'Pilih Batas Waktu'**
  String get pickDeadlineDate;

  /// Hour label
  ///
  /// In id, this message translates to:
  /// **'Jam'**
  String get hour;

  /// Minute label
  ///
  /// In id, this message translates to:
  /// **'Menit'**
  String get minute;

  /// Date field label
  ///
  /// In id, this message translates to:
  /// **'Tanggal Deadline'**
  String get dateFieldLabel;

  /// Date field hint
  ///
  /// In id, this message translates to:
  /// **'dd/mm/yyyy'**
  String get dateFieldHint;

  /// Invalid date format error
  ///
  /// In id, this message translates to:
  /// **'Format tanggal tidak valid'**
  String get invalidDateFormat;

  /// Invalid date error
  ///
  /// In id, this message translates to:
  /// **'Tanggal tidak valid'**
  String get invalidDate;

  /// Choose button
  ///
  /// In id, this message translates to:
  /// **'Pilih'**
  String get choose;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
