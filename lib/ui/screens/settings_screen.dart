import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  // Use singleton instances instead of creating new ones
  final _backupService = BackupService();
  final _notificationService = NotificationService();
  final _preferencesRepository = PreferencesRepository();
  
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
      await _preferencesRepository.saveNotificationsEnabled(enabled);
      _notificationService.setNotificationsEnabled(enabled);
      
      if (enabled) {
        await _notificationService.requestPermissions();
      }
    } catch (e) {
      setState(() {
        _notificationsEnabled = !enabled;
      });
      
      if (mounted) {
        _showErrorSnackBar(l10n.notificationSaveError);
      }
    }
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// Export data to JSON file via system save dialog
  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jsonData = await _backupService.exportToJson();
      
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
      final fileName = 'tugas_backup_$timestamp.json';
      
      final bytes = Uint8List.fromList(utf8.encode(jsonData));
      
      final result = await FilePicker.platform.saveFile(
        dialogTitle: l10n.saveBackupFile,
        fileName: fileName,
        bytes: bytes,
      );
      
      if (result != null) {
        if (mounted) {
          _showSuccessSnackBar(l10n.exportSuccess);
        }
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
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final file = File(result.files.first.path!);
      final jsonData = await file.readAsString();

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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                _buildSectionHeader(l10n.notifications, Icons.notifications),
                const SizedBox(height: 8),
                _buildNotificationTile(theme),
                const SizedBox(height: 24),

                _buildSectionHeader(l10n.backup, Icons.backup),
                const SizedBox(height: 8),
                _buildBackupTiles(theme),
                const SizedBox(height: 24),

                _buildSectionHeader(l10n.about, Icons.info),
                const SizedBox(height: 8),
                _buildAboutTiles(theme),
              ],
            ),
    );
  }

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

  Widget _buildNotificationTile(ThemeData theme) {
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

  Widget _buildBackupTiles(ThemeData theme) {
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

  Widget _buildAboutTiles(ThemeData theme) {
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
            subtitle: Text(l10n.developerTeam),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.school,
              color: theme.colorScheme.primary,
            ),
            title: Text(l10n.appTitle),
            subtitle: Text(l10n.appDescription),
          ),
        ],
      ),
    );
  }
}
