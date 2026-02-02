import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/l10n/app_localizations_id.dart';

/// Property-based tests for Indonesian localization completeness
/// 
/// **Feature: academic-task-manager, Property 26: Indonesian localization completeness**
/// **Validates: Requirements 11.1, 11.2, 11.3, 11.4**
/// 
/// Tests that all user interface elements, error messages, and notifications
/// are displayed in Indonesian language using appropriate terminology.
void main() {
  group('Indonesian Localization Property Tests', () {
    late AppLocalizationsId l10n;

    setUpAll(() {
      // Initialize Indonesian localization directly
      l10n = AppLocalizationsId();
    });

    /// **Feature: academic-task-manager, Property 26: Indonesian localization completeness**
    /// **Validates: Requirements 11.1, 11.2, 11.3, 11.4**
    /// 
    /// Property: For any user interface element, error message, or notification,
    /// the text should be displayed in Indonesian language using appropriate terminology
    test('Property 26: Indonesian localization completeness', () {
      // Test academic terminology (Requirement 11.2)
      expect(l10n.uts, equals('UTS'));
      expect(l10n.uas, equals('UAS'));
      expect(l10n.semester, equals('Semester'));
      expect(l10n.tugas, equals('Tugas'));
      expect(l10n.progres, equals('Progres'));
      expect(l10n.utsLong, equals('Ujian Tengah Semester'));
      expect(l10n.uasLong, equals('Ujian Akhir Semester'));
      expect(l10n.mataKuliah, equals('Mata Kuliah'));
      expect(l10n.dosen, equals('Dosen'));

      // Test UI elements in Indonesian (Requirement 11.1)
      expect(l10n.appTitle, equals('Tazk'));
      expect(l10n.taskList, equals('Daftar Tugas'));
      expect(l10n.addTask, equals('Tambah Tugas'));
      expect(l10n.settings, equals('Pengaturan'));
      expect(l10n.notifications, equals('Notifikasi'));
      expect(l10n.backup, equals('Cadangan'));
      expect(l10n.about, equals('Tentang'));
      expect(l10n.sortBy, equals('Urutkan berdasarkan'));
      expect(l10n.deadline, equals('Batas Waktu'));

      // Test error messages in Indonesian (Requirement 11.3)
      expect(l10n.pleaseSelectSemester, equals('Silakan pilih semester'));
      expect(l10n.pleaseSelectPeriod, equals('Silakan pilih periode'));
      expect(l10n.taskNameRequired, equals('Nama tugas tidak boleh kosong'));
      expect(l10n.courseNameRequired, equals('Mata kuliah tidak boleh kosong'));
      expect(l10n.instructorNameRequired, equals('Nama dosen tidak boleh kosong'));
      expect(l10n.deadlineRequired, equals('Silakan pilih batas waktu tugas'));
      expect(l10n.semesterRequired, equals('Silakan pilih semester'));
      expect(l10n.periodRequired, equals('Silakan pilih periode'));
      expect(l10n.progressRangeError, equals('Progres harus antara 0-100%'));

      // Test notification messages in Indonesian (Requirement 11.4)
      expect(l10n.taskAddedSuccess, equals('Tugas berhasil ditambahkan'));
      expect(l10n.taskUpdatedSuccess, equals('Tugas berhasil diperbarui'));
      expect(l10n.taskDeletedSuccess, equals('Tugas berhasil dihapus'));
      expect(l10n.exportSuccess, equals('Data berhasil diekspor'));
      expect(l10n.importError, equals('Gagal mengimpor data'));
      expect(l10n.exportError, equals('Gagal mengekspor data'));

      // Test status indicators in Indonesian
      expect(l10n.completed, equals('Selesai'));
      expect(l10n.overdue, equals('Terlambat'));
      expect(l10n.today, equals('Hari ini'));
      expect(l10n.tomorrow, equals('Besok'));
      expect(l10n.notStarted, equals('Belum Dimulai'));
      expect(l10n.inProgress, equals('Dalam Progres'));
      expect(l10n.almostDone, equals('Hampir Selesai'));

      // Test form labels and hints in Indonesian
      expect(l10n.taskName, equals('Nama Tugas'));
      expect(l10n.courseName, equals('Mata Kuliah'));
      expect(l10n.instructorName, equals('Nama Dosen'));
      expect(l10n.taskNameHint, equals('Masukkan nama tugas'));
      expect(l10n.courseNameHint, equals('Masukkan nama mata kuliah'));
      expect(l10n.instructorNameHint, equals('Masukkan nama dosen'));

      // Test button labels in Indonesian
      expect(l10n.continueButton, equals('Lanjutkan'));
      expect(l10n.cancel, equals('Batal'));
      expect(l10n.delete, equals('Hapus'));
      expect(l10n.choose, equals('Pilih'));
      expect(l10n.updateTask, equals('Perbarui Tugas'));

      // Test setup and navigation text in Indonesian
      expect(l10n.setupTitle, equals('Pengaturan Awal'));
      expect(l10n.setupSubtitle, equals('Pilih semester dan periode untuk memulai'));
      expect(l10n.selectSemester, equals('Pilih Semester'));
      expect(l10n.selectPeriod, equals('Pilih Periode'));
      expect(l10n.noTasks, equals('Belum ada tugas'));
      expect(l10n.noTasksSubtitle, equals('Tekan tombol + untuk menambah tugas baru'));

      // Test that all strings are non-empty and contain Indonesian characters/words
      final allStrings = [
        l10n.appTitle, l10n.semester, l10n.uts, l10n.uas, l10n.tugas,
        l10n.progres, l10n.deadline, l10n.mataKuliah, l10n.dosen,
        l10n.setupTitle, l10n.setupSubtitle, l10n.taskList, l10n.addTask,
        l10n.settings, l10n.notifications, l10n.backup, l10n.about,
        l10n.completed, l10n.overdue, l10n.continueButton, l10n.cancel,
      ];

      for (final string in allStrings) {
        expect(string.isNotEmpty, isTrue, reason: 'String should not be empty: $string');
        expect(string.trim(), equals(string), reason: 'String should not have leading/trailing whitespace: $string');
      }
    });

    /// Test parametrized strings with Indonesian formatting
    test('Property 26: Parametrized strings use Indonesian formatting', () {
      // Test remaining days formatting
      expect(l10n.remainingDays(1), equals('1 hari tersisa'));
      expect(l10n.remainingDays(5), equals('5 hari tersisa'));
      expect(l10n.remainingDays(10), equals('10 hari tersisa'));

      // Test days remaining formatting
      expect(l10n.daysRemaining(1), equals('1 hari lagi'));
      expect(l10n.daysRemaining(3), equals('3 hari lagi'));
      expect(l10n.daysRemaining(7), equals('7 hari lagi'));

      // Test overdue formatting
      expect(l10n.overdueByDays(2), equals('Terlambat 2 hari'));
      expect(l10n.overdueByDays(5), equals('Terlambat 5 hari'));
      expect(l10n.overdueByDay, equals('Terlambat 1 hari'));

      // Test import success formatting
      expect(l10n.importSuccess(1), equals('Berhasil mengimpor 1 tugas'));
      expect(l10n.importSuccess(5), equals('Berhasil mengimpor 5 tugas'));
      expect(l10n.importSuccess(10), equals('Berhasil mengimpor 10 tugas'));

      // Test delete confirmation formatting
      expect(l10n.deleteTaskConfirm('Test Task'), 
        equals('Apakah Anda yakin ingin menghapus tugas "Test Task"?\n\nTindakan ini tidak dapat dibatalkan.'));
    });

    /// Test that Indonesian terminology is consistently used
    test('Property 26: Indonesian academic terminology consistency', () {
      // Verify UTS/UAS terminology is used consistently
      expect(l10n.uts, equals('UTS'));
      expect(l10n.uas, equals('UAS'));
      expect(l10n.utsLong, contains('Ujian Tengah Semester'));
      expect(l10n.uasLong, contains('Ujian Akhir Semester'));

      // Verify academic terms are in Indonesian
      expect(l10n.semester, equals('Semester'));
      expect(l10n.tugas, equals('Tugas'));
      expect(l10n.progres, equals('Progres'));
      expect(l10n.mataKuliah, equals('Mata Kuliah'));
      expect(l10n.dosen, equals('Dosen'));

      // Verify no English academic terms are used in Indonesian context
      expect(l10n.tugas, isNot(contains('Task')), reason: 'Should use Indonesian term');
      expect(l10n.progres, isNot(contains('Progress')), reason: 'Should use Indonesian term');
      expect(l10n.mataKuliah, isNot(contains('Course')), reason: 'Should use Indonesian term');
      expect(l10n.dosen, isNot(contains('Instructor')), reason: 'Should use Indonesian term');
      expect(l10n.dosen, isNot(contains('Teacher')), reason: 'Should use Indonesian term');
      
      // Verify Indonesian-specific academic terms
      expect(l10n.utsLong, contains('Ujian'));
      expect(l10n.uasLong, contains('Ujian'));
      expect(l10n.mataKuliah, contains('Mata'));
      expect(l10n.mataKuliah, contains('Kuliah'));
    });

    /// Test sort option descriptions in Indonesian
    test('Property 26: Sort options use Indonesian descriptions', () {
      expect(l10n.sortByDeadline, equals('Batas Waktu'));
      expect(l10n.sortByProgress, equals('Progres'));
      expect(l10n.sortByCourseName, equals('Mata Kuliah'));
      expect(l10n.sortByTaskName, equals('Nama Tugas'));

      expect(l10n.sortByDeadlineDesc, equals('Urutkan berdasarkan batas waktu (terdini ke terakhir)'));
      expect(l10n.sortByProgressDesc, equals('Urutkan berdasarkan progres (terendah ke tertinggi)'));
      expect(l10n.sortByCourseNameDesc, equals('Urutkan berdasarkan nama mata kuliah (A-Z)'));
      expect(l10n.sortByTaskNameDesc, equals('Urutkan berdasarkan nama tugas (A-Z)'));
    });

    /// Test progress status terms in Indonesian
    test('Property 26: Progress status uses Indonesian terms', () {
      expect(l10n.notStarted, equals('Belum Dimulai'));
      expect(l10n.justStarted, equals('Baru Dimulai'));
      expect(l10n.inProgress, equals('Dalam Progres'));
      expect(l10n.halfWay, equals('Setengah Jalan'));
      expect(l10n.almostDone, equals('Hampir Selesai'));
      expect(l10n.completed, equals('Selesai'));
    });
  });
}