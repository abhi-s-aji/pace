import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/pace_colors.dart';
import '../onboarding/onboarding_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openUrl(BuildContext context, String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString);
      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $urlString'),
            backgroundColor: PaceColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $e'),
            backgroundColor: PaceColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Pace'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: PaceColors.lightTextPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/pace_logo.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pace',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  color: PaceColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'Version 1.0',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: PaceColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Personal consistency & progress.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: PaceColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Small actions. Real progress.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PaceColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pace helps you choose what matters, build intentional habits, take daily action, and record your consistency over time.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: PaceColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // FEATURES Section
              _buildSectionHeader('Features'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildFeatureRow(Icons.check_circle_outline_rounded, 'Habits & tasks'),
                      _buildFeatureRow(Icons.timer_rounded, 'Focus sessions'),
                      _buildFeatureRow(Icons.flag_rounded, 'Goals & milestones'),
                      _buildFeatureRow(Icons.calendar_today_rounded, 'Daily history'),
                      _buildFeatureRow(Icons.edit_note_rounded, 'Journal'),
                      _buildFeatureRow(Icons.insights_rounded, 'Statistics & progress'),
                      _buildFeatureRow(Icons.grid_on_rounded, 'Consistency map'),
                      _buildFeatureRow(Icons.emoji_events_rounded, 'Achievements'),
                      _buildFeatureRow(Icons.backup_rounded, 'Backup & restore'),
                      _buildFeatureRow(Icons.storage_rounded, 'Offline-first local data', isLast: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // HOW CAN YOU USE PACE? Section
              _buildSectionHeader('How can you use Pace?'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pace is designed around a simple, repeatable loop for intentional personal progress:',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: PaceColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildCoreLoopNode('Goal', 'Define what you want to achieve'),
                      _buildLoopArrow(),
                      _buildCoreLoopNode('Habit / Action', 'Break it down into regular actions'),
                      _buildLoopArrow(),
                      _buildCoreLoopNode('Completion', 'Log daily completions & focus sessions'),
                      _buildLoopArrow(),
                      _buildCoreLoopNode('Daily Progress', 'See your daily progress graph & streaks'),
                      _buildLoopArrow(),
                      _buildCoreLoopNode('History', 'Review day-by-day progress in daily history'),
                      _buildLoopArrow(),
                      _buildCoreLoopNode('Long-term Consistency', 'Build lasting consistency over months'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // UNDERSTANDING PACE & REFERENCE Section
              _buildSectionHeader('Understanding Pace'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHelpTopic(
                        icon: Icons.timer_outlined,
                        title: 'Focus Sessions',
                        description:
                            'Dedicated time spent actively working on an activity or habit. When a timer completes, the session is recorded automatically into your daily history and statistics.',
                      ),
                      const Divider(height: 24),
                      _buildHelpTopic(
                        icon: Icons.edit_note_rounded,
                        title: 'Reflection Time',
                        description:
                            'An optional, short note prompt presented immediately after completing a Focus session. Its purpose is to let you briefly record what you accomplished or noticed. Reflection Time is NOT another Focus session and does NOT require equal reflection time.',
                      ),
                      const Divider(height: 24),
                      _buildHelpTopic(
                        icon: Icons.book_outlined,
                        title: 'Journal / Daily Reflection',
                        description:
                            'An optional daily written entry for capturing broader thoughts or notes about your day. Journal entries are created independently and are separate from short Focus completion notes.',
                      ),
                      const Divider(height: 24),
                      _buildHelpTopic(
                        icon: Icons.access_time_rounded,
                        title: 'Default Focus Duration',
                        description:
                            'The initial timer duration selected when launching a Focus session. You can adjust the session length anytime before starting. Updating your default preference in Settings does not modify previously completed sessions.',
                      ),
                      const Divider(height: 24),
                      _buildHelpTopic(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Habits',
                        description:
                            'Recurring actions you want to maintain. Completing a habit records your progress for that day, contributing to your streaks, history, and consistency map.',
                      ),
                      const Divider(height: 24),
                      _buildHelpTopic(
                        icon: Icons.grid_on_rounded,
                        title: 'Contribution / Consistency Map',
                        description:
                            'A visual grid depicting your daily activity intensity over time. Intensity levels are calculated automatically from your recorded completions and focus sessions—it is not a manually edited calendar.',
                      ),
                      const Divider(height: 24),
                      _buildHelpTopic(
                        icon: Icons.flag_outlined,
                        title: 'Goals',
                        description:
                            'Long-term milestones connected to your habits or focus activities. Goal progress advances automatically based on actual logged activities rather than arbitrary manual edits.',
                      ),
                      const Divider(height: 24),
                      _buildHelpTopic(
                        icon: Icons.calendar_today_rounded,
                        title: 'Daily History',
                        description:
                            'A chronological log of all past activities, completions, and notes. You can revisit any previous date. Missing a day does not delete or alter your past historical data.',
                      ),
                      const Divider(height: 24),
                      _buildHelpTopic(
                        icon: Icons.lock_outline_rounded,
                        title: 'Data & Privacy',
                        description:
                            'Pace is built offline-first. Your habits, focus sessions, and journal entries are stored locally on your device. You can export or import JSON backups anytime in Settings to keep your data safe.',
                      ),
                      const Divider(height: 24),
                      _buildHelpTopic(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        description:
                            'Optional, gentle reminders designed to support your routines without pressure. You can customize or disable reminder schedules in Settings.',
                      ),
                      const Divider(height: 24),
                      _buildHelpTopic(
                        icon: Icons.emoji_events_outlined,
                        title: 'Achievements',
                        description:
                            'Badges unlocked automatically as you reach key milestones in habit completions, focus hours, and active days. Achievements celebrate your consistency without locking core features.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // DEVELOPED BY Section
              _buildSectionHeader('Developed By'),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Abhi S Aji',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PaceColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _buildLinkTile(
                      context: context,
                      icon: Icons.code_rounded,
                      label: 'GitHub',
                      subtitle: 'abhi-s-aji',
                      url: 'https://github.com/abhi-s-aji',
                    ),
                    const Divider(height: 1),
                    _buildLinkTile(
                      context: context,
                      icon: Icons.work_outline_rounded,
                      label: 'LinkedIn',
                      subtitle: 'abhi-s-aji-eden',
                      url: 'https://www.linkedin.com/in/abhi-s-aji-eden',
                    ),
                    const Divider(height: 1),
                    _buildLinkTile(
                      context: context,
                      icon: Icons.article_outlined,
                      label: 'Hashnode',
                      subtitle: '@abhi-s-aji',
                      url: 'https://hashnode.com/@abhi-s-aji',
                    ),
                    const Divider(height: 1),
                    _buildLinkTile(
                      context: context,
                      icon: Icons.folder_zip_outlined,
                      label: 'Pace Repository',
                      subtitle: 'abhi-s-aji/pace',
                      url: 'https://github.com/abhi-s-aji/pace',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Introduction Revisit Entry
              Card(
                child: ListTile(
                  leading: Icon(Icons.auto_stories_rounded, color: PaceColors.primary),
                  title: const Text('Introduction to Pace', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Revisit the onboarding intro slides', style: TextStyle(fontSize: 12)),
                  trailing: Icon(Icons.chevron_right_rounded, color: PaceColors.lightTextMuted),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OnboardingPage(isRevisit: true)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
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

  Widget _buildFeatureRow(IconData icon, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: PaceColors.primary),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: PaceColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreLoopNode(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PaceColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PaceColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: PaceColors.primary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: PaceColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoopArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Icon(
          Icons.arrow_downward_rounded,
          size: 14,
          color: PaceColors.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildHelpTopic({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: PaceColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: PaceColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: PaceColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required String url,
  }) {
    return Semantics(
      label: '$label: $subtitle. Opens external link.',
      button: true,
      child: ListTile(
        leading: Icon(icon, size: 20, color: PaceColors.primary),
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: PaceColors.lightTextMuted)),
        trailing: Icon(Icons.open_in_new_rounded, size: 16, color: PaceColors.lightTextMuted),
        onTap: () => _openUrl(context, url),
      ),
    );
  }
}
