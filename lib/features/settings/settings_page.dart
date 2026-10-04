import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/domain/models/models.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/achievement_detail_sheet.dart';
import '../about/about_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paceAppProvider);
    final prefs = state.preferences;
    final earnedBadges = state.achievements.where((a) => a.isEarned).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.8,
                        color: PaceColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile Section
                _buildSectionHeader('Profile'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: PaceColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  prefs.userName.isNotEmpty ? prefs.userName[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: PaceColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prefs.userName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${state.consistencyStats.activeDays} active days · ${state.habits.where((h) => !h.isArchived).length} habits',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: PaceColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _editNameDialog(context, ref, prefs),
                              icon: Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: PaceColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        if (prefs.showProfileAchievements) ...[
                          const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Earned Badges (${earnedBadges.length}/${state.achievements.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: PaceColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (earnedBadges.isEmpty)
                          Text(
                            'No badges earned yet. Complete habits or focus sessions to collect badges.',
                            style: TextStyle(
                              fontSize: 12,
                              color: PaceColors.lightTextMuted,
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: earnedBadges.map((ach) {
                                final iconData = getAchievementIconData(ach.icon);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => AchievementDetailSheet(achievement: ach),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: PaceColors.secondary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: PaceColors.secondary.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(iconData, size: 16, color: PaceColors.secondary),
                                          const SizedBox(width: 6),
                                          Text(
                                            ach.title,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: PaceColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Notifications Section (Phase 5)
                _buildSectionHeader('Notifications & Reminders'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Allow Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          prefs.notificationsEnabled ? 'Local scheduled reminders enabled' : 'All Pace reminders paused',
                          style: TextStyle(
                            fontSize: 13,
                            color: PaceColors.lightTextMuted,
                          ),
                        ),
                        value: prefs.notificationsEnabled,
                        onChanged: (val) async {
                          if (val) {
                            final granted = await ref.read(notificationServiceProvider).requestPermission();
                            if (!context.mounted) return;
                            if (!granted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notifications are disabled for Pace in system settings.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                          ref.read(paceAppProvider.notifier).updatePreferences(
                                prefs.copyWith(notificationsEnabled: val),
                              );
                        },
                      ),
                      if (prefs.notificationsEnabled) ...[
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Habit Reminders', style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                            'Reminders for scheduled habits',
                            style: TextStyle(
                              fontSize: 12,
                              color: PaceColors.lightTextMuted,
                            ),
                          ),
                          value: prefs.habitRemindersEnabled,
                          onChanged: (val) {
                            ref.read(paceAppProvider.notifier).updatePreferences(
                                  prefs.copyWith(habitRemindersEnabled: val),
                                );
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Goal Reminders', style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                            'Gentle reminders for active goals',
                            style: TextStyle(
                              fontSize: 12,
                              color: PaceColors.lightTextMuted,
                            ),
                          ),
                          value: prefs.goalRemindersEnabled,
                          onChanged: (val) {
                            ref.read(paceAppProvider.notifier).updatePreferences(
                                  prefs.copyWith(goalRemindersEnabled: val),
                                );
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Daily Reflection', style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                            'Evening reminder to reflect & journal',
                            style: TextStyle(
                              fontSize: 12,
                              color: PaceColors.lightTextMuted,
                            ),
                          ),
                          value: prefs.dailyReflectionEnabled,
                          onChanged: (val) {
                            ref.read(paceAppProvider.notifier).updatePreferences(
                                  prefs.copyWith(dailyReflectionEnabled: val),
                                );
                          },
                        ),
                        if (prefs.dailyReflectionEnabled) ...[
                          ListTile(
                            title: const Text('Reflection Time', style: TextStyle(fontSize: 14)),
                            subtitle: Text(prefs.dailyReflectionTime, style: const TextStyle(fontSize: 12)),
                            trailing: Icon(
                              Icons.access_time_rounded,
                              size: 20,
                              color: PaceColors.lightTextMuted,
                            ),
                            onTap: () => _selectReflectionTime(context, ref, prefs),
                          ),
                        ],
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Quiet Hours', style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                            prefs.quietHoursEnabled
                                ? 'Active: ${prefs.quietHoursStart} to ${prefs.quietHoursEnd}'
                                : 'Suppress notifications during quiet hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: PaceColors.lightTextMuted,
                            ),
                          ),
                          value: prefs.quietHoursEnabled,
                          onChanged: (val) {
                            ref.read(paceAppProvider.notifier).updatePreferences(
                                  prefs.copyWith(quietHoursEnabled: val),
                                );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Appearance
                _buildSectionHeader('Appearance'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Accent Color',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildAccentOption(ref, prefs, 'green', 'Green', const Color(0xFF0D9488)),
                            _buildAccentOption(ref, prefs, 'blue', 'Blue', const Color(0xFF0284C7)),
                            _buildAccentOption(ref, prefs, 'purple', 'Purple', const Color(0xFF7C3AED)),
                            _buildAccentOption(ref, prefs, 'orange', 'Orange', const Color(0xFFEA580C)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Prompt for completion notes', style: TextStyle(fontSize: 15)),
                        subtitle: Text(
                          prefs.completionNotePreference == 'ask'
                              ? 'Ask for optional notes on completions'
                              : 'Complete immediately without notes',
                          style: TextStyle(
                            fontSize: 13,
                            color: PaceColors.lightTextMuted,
                          ),
                        ),
                        value: prefs.completionNotePreference == 'ask',
                        onChanged: (val) {
                          ref.read(paceAppProvider.notifier).updatePreferences(
                                prefs.copyWith(completionNotePreference: val ? 'ask' : 'dont_ask'),
                              );
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Start week on Monday', style: TextStyle(fontSize: 15)),
                        subtitle: Text(
                          prefs.firstDayIsMonday ? 'Monday is first day' : 'Sunday is first day',
                          style: TextStyle(
                            fontSize: 13,
                            color: PaceColors.lightTextMuted,
                          ),
                        ),
                        value: prefs.firstDayIsMonday,
                        onChanged: (val) {
                          ref.read(paceAppProvider.notifier).updatePreferences(
                                prefs.copyWith(firstDayIsMonday: val),
                              );
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Show achievements on profile', style: TextStyle(fontSize: 15)),
                        subtitle: Text(
                          prefs.showProfileAchievements
                              ? 'Earned badges preview shown on Profile'
                              : 'Badges preview hidden on Profile',
                          style: TextStyle(
                            fontSize: 13,
                            color: PaceColors.lightTextMuted,
                          ),
                        ),
                        value: prefs.showProfileAchievements,
                        onChanged: (val) {
                          ref.read(paceAppProvider.notifier).updatePreferences(
                                prefs.copyWith(showProfileAchievements: val),
                              );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Focus Defaults
                _buildSectionHeader('Focus Sessions'),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Default duration', style: TextStyle(fontSize: 15)),
                    subtitle: Text(
                      '${prefs.defaultFocusDuration} minutes',
                      style: TextStyle(
                        fontSize: 13,
                        color: PaceColors.lightTextMuted,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: PaceColors.lightTextMuted,
                    ),
                    onTap: () => _selectFocusDuration(context, ref, prefs),
                  ),
                ),
                const SizedBox(height: 20),

                // Data Management
                _buildSectionHeader('Data'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: PaceColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.upload_file_rounded, size: 18, color: PaceColors.primary),
                        ),
                        title: const Text('Export Data (JSON)', style: TextStyle(fontSize: 15)),
                        subtitle: const Text('Full backup of all data', style: TextStyle(fontSize: 13)),
                        onTap: () => _exportData(context, ref),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: PaceColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.download_rounded, size: 18, color: PaceColors.info),
                        ),
                        title: const Text('Import Backup', style: TextStyle(fontSize: 15)),
                        subtitle: const Text('Restore from JSON file', style: TextStyle(fontSize: 13)),
                        onTap: () => _importData(context, ref),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: PaceColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.delete_forever_rounded, size: 18, color: PaceColors.error),
                        ),
                        title: const Text(
                          'Clear All Data',
                          style: TextStyle(fontSize: 15, color: PaceColors.error),
                        ),
                        subtitle: const Text('Permanently delete everything', style: TextStyle(fontSize: 13)),
                        onTap: () => _confirmClearData(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // About Section
                _buildSectionHeader('About'),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: PaceColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.info_outline_rounded, size: 18, color: PaceColors.primary),
                    ),
                    title: const Text('About Pace', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Learn about Pace, its features and the project behind it.', style: TextStyle(fontSize: 13)),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: PaceColors.lightTextMuted,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: PaceColors.lightTextMuted,
      ),
    );
  }

  Future<void> _selectReflectionTime(BuildContext context, WidgetRef ref, UserPreferences prefs) async {
    final parts = prefs.dailyReflectionTime.split(':');
    final initialTime = TimeOfDay(
      hour: parts.length == 2 ? int.tryParse(parts[0]) ?? 21 : 21,
      minute: parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await ref.read(paceAppProvider.notifier).updatePreferences(
            prefs.copyWith(dailyReflectionTime: formatted),
          );
    }
  }

  void _editNameDialog(BuildContext context, WidgetRef ref, UserPreferences prefs) {
    final controller = TextEditingController(text: prefs.userName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Your name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref.read(paceAppProvider.notifier).updatePreferences(
                        prefs.copyWith(userName: name),
                      );
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _selectFocusDuration(BuildContext context, WidgetRef ref, UserPreferences prefs) {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Default Focus Duration'),
          children: ['15', '25', '45', '60', '90'].map((dur) {
            return SimpleDialogOption(
              onPressed: () {
                ref.read(paceAppProvider.notifier).updatePreferences(
                      prefs.copyWith(defaultFocusDuration: dur),
                    );
                Navigator.of(ctx).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '$dur minutes',
                  style: TextStyle(
                    fontWeight: dur == prefs.defaultFocusDuration ? FontWeight.bold : FontWeight.normal,
                    color: dur == prefs.defaultFocusDuration ? PaceColors.primary : null,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final backupRepo = ref.read(backupRepositoryProvider);
      final data = await backupRepo.exportAllDataJson();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      final nowStr = PaceDateUtils.toIsoDateString(DateTime.now());
      final fileName = 'pace-backup-$nowStr.json';

      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsString(jsonStr);

      final xFile = XFile(file.path, mimeType: 'application/json');
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'Pace Backup ($nowStr)',
          text: 'Pace backup export file ($fileName)',
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup exported: $fileName'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: PaceColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isEmpty) return;

      final filePath = files.first.path;
      if (filePath == null) return;

      final file = File(filePath);
      final content = await file.readAsString();

      Map<String, dynamic> jsonData;
      try {
        jsonData = Map<String, dynamic>.from(jsonDecode(content));
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invalid file format. Please select a valid JSON backup file.'),
              backgroundColor: PaceColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Structural & metadata validation
      try {
        final metadataJson = jsonData['metadata'];
        if (metadataJson is! Map) {
          throw const FormatException('Missing or invalid metadata section.');
        }
        final metadata = BackupMetadata.fromJson(Map<String, dynamic>.from(metadataJson));
        if (metadata.backupVersion > 1) {
          throw FormatException('Unsupported backup version ${metadata.backupVersion}.');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid Pace backup: ${e.toString()}'),
              backgroundColor: PaceColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;

      // Confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore this backup?'),
          content: const Text(
            'Your current Pace data will be replaced by the selected backup.\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: PaceColors.primary),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await ref.read(paceAppProvider.notifier).restoreBackup(jsonData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: PaceColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Clear all data?'),
          content: const Text(
            'This permanently removes your habits, activity history, goals, focus sessions, journal entries, achievements and other personal Pace data from this device.\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(paceAppProvider.notifier).clearAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All personal data cleared.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: PaceColors.error),
              child: const Text('Clear all data'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccentOption(WidgetRef ref, UserPreferences prefs, String id, String name, Color displayColor) {
    final isSelected = prefs.accentColor == id;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          ref.read(paceAppProvider.notifier).updatePreferences(
                prefs.copyWith(accentColor: id),
              );
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? displayColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? displayColor : PaceColors.lightBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: displayColor,
                shape: BoxShape.circle,
              ),
              child: isSelected 
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: PaceColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
