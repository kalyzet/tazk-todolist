import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../services/backup_service.dart';
import '../../services/notification_service.dart';
import '../../repositories/preferences_repository.dart';

/// Settings screen with notification toggle, backup functionality, and app info
/// 
/// Features:
/// - Notification enable/disable toggle
/// - Backup export functionality with file picker
/// - Backup import functionality with file validation
/// - About section with app information
/// 
/// Requirements: 8.1, 8.2, 8.5, 9.5
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  final NotificationService _notificationService = NotificationService();
  final PreferencesRepository _preferencesRepository = PreferencesRepository();
  
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  /// Load notification preference from storage
  Future<void> _loadNotificationPreference() async {
    try {
      final enabled = await _preferencesRepository.getNotificationsEnabled();
      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
        });
      }
    } catch (e) {
      // Use default value on error
      if (mounted) {
        setState(() {
          _notificationsEnabled = true;
        });
      }
    }
  }

  /// Toggle notification preference
  Future<void> _toggleNotifications(bool enabled) async {
    setState(() {
      _notificationsEnabled = enabled;
    });

    try {
      // Save preference to storage
      await _preferencesRepository.saveNotificationsEnabled(enabled);
      
      // Update notification service
      _notificationService.setNotificationsEnabled(enabled);
      
      // Request permissions if enabling notifications
      if (enabled) {
        await _notificationService.requestPermissions();
      }
    } catch (e) {
      // Revert state on error
      setState(() {
        _notificationsEnabled = !enabled;
      });
      
      if (mounted) {
        _showErrorSnackBar('Gagal menyimpan pengaturan notifikasi');
      }
    }
  }

  /// Export data to JSON file
  Future<void> _exportData() async {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final permission = await Permission.storage.request();
        if (permission != PermissionStatus.granted) {
          if (mounted) {
            _showErrorSnackBar('Izin akses penyimpanan diperlukan untuk ekspor data');
          }
          return;
        }
      }

      // Generate JSON data
      final jsonData = await _backupService.exportToJson();
      
      // Get Downloads directory
      Directory? directory;
      String locationMessage = '';
      
      if (Platform.isAndroid) {
        // For Android, try to use the public Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        
        // Check if the directory exists and is writable
        if (!await directory.exists()) {
          // Try alternative paths
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directory = Directory('${externalDir.path}/Download');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } else {
            // Final fallback to application documents directory
            directory = await getApplicationDocumentsDirectory();
          }
        }
        locationMessage = 'File tersimpan di folder Download';
      } else if (Platform.isIOS) {
        // For iOS, use Documents directory (accessible via Files app)
        directory = await getApplicationDocumentsDirectory();
        locationMessage = 'File tersimpan di Documents aplikasi (dapat diakses via Files app)';
      } else {
        // For other platforms, try Downloads directory
        try {
          directory = await getDownloadsDirectory();
          locationMessage = 'File tersimpan di folder Downloads';
        } catch (e) {
          // Fallback to documents directory
          directory = await getApplicationDocumentsDirectory();
          locationMessage = 'File tersimpan di folder Documents';
        }
      }
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = 'tugas_backup_$timestamp.json';
      final filePath = '${directory!.path}/$fileName';
      
      // Write file
      final file = File(filePath);
      await file.writeAsString(jsonData);
      
      if (mounted) {
        _showSuccessSnackBar('${l10n.exportSuccess}\n$locationMessage\nNama file: $fileName');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('${l10n.exportError}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Import data from JSON file
  Future<void> _importData() async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      setState(() {
        _isLoading = true;
      });

      final file = File(result.files.first.path!);
      final jsonData = await file.readAsString();

      // Import data
      final importedCount = await _backupService.importFromJson(jsonData);
      
      if (mounted) {
        _showSuccessSnackBar(l10n.importSuccess(importedCount));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(l10n.importError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show success snack bar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error snack bar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Notifications Section
                _buildSectionHeader(l10n.notifications, Icons.notifications),
                const SizedBox(height: 8),
                _buildNotificationTile(l10n, theme),
                const SizedBox(height: 24),

                // Backup Section
                _buildSectionHeader(l10n.backup, Icons.backup),
                const SizedBox(height: 8),
                _buildBackupTiles(l10n, theme),
                const SizedBox(height: 24),

                // About Section
                _buildSectionHeader(l10n.about, Icons.info),
                const SizedBox(height: 8),
                _buildAboutTiles(l10n, theme),
              ],
            ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Build notification toggle tile
  Widget _buildNotificationTile(AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: SwitchListTile(
        title: Text(l10n.enableNotifications),
        subtitle: Text(l10n.notificationDescription),
        value: _notificationsEnabled,
        onChanged: _toggleNotifications,
        secondary: Icon(
          _notificationsEnabled ? Icons.notifications : Icons.notifications_off,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  /// Build backup tiles
  Widget _buildBackupTiles(AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.upload,
              color: theme.colorScheme.primary,
            ),
            title: Text(l10n.exportData),
            subtitle: Text(l10n.exportDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportData,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.download,
              color: theme.colorScheme.primary,
            ),
            title: Text(l10n.importData),
            subtitle: Text(l10n.importDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: _importData,
          ),
        ],
      ),
    );
  }

  /// Build about tiles
  Widget _buildAboutTiles(AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.info,
              color: theme.colorScheme.primary,
            ),
            title: Text(l10n.appVersion),
            subtitle: const Text('1.0.0'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
            ),
            title: Text(l10n.developer),
            subtitle: const Text('Kalyzet Team'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.school,
              color: theme.colorScheme.primary,
            ),
            title: Text(l10n.appTitle),
            subtitle: const Text('Aplikasi manajemen tugas untuk mahasiswa'),
          ),
        ],
      ),
    );
  }
}