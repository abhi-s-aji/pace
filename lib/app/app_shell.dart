import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../core/notifications/notification_service.dart';
import '../core/state/pace_providers.dart';
import '../core/utils/date_utils.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/habits/habits_page.dart';
import '../features/focus/focus_page.dart';
import '../features/progress/progress_page.dart';
import '../features/journal/journal_editor_sheet.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardPage(),
    HabitsPage(),
    FocusPage(),
    ProgressPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).initialize(
            onNotificationSelect: _handleNotificationPayload,
          );
      _setupWidgetLinks();
    });
  }

  void _setupWidgetLinks() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
    HomeWidget.widgetClicked.listen(_handleWidgetUri);
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || !mounted) return;
    if (uri.host == 'complete_habit') {
      final habitId = uri.queryParameters['id'];
      if (habitId != null && habitId.isNotEmpty) {
        final todayStr = PaceDateUtils.toIsoDateString(DateTime.now());
        ref.read(paceAppProvider.notifier).completeHabit(habitId, todayStr);
      }
    }
  }

  void _handleNotificationPayload(String payload) {
    if (!mounted) return;

    if (payload.startsWith('habit:')) {
      setState(() => _currentIndex = 1);
    } else if (payload.startsWith('goal:')) {
      setState(() => _currentIndex = 0);
    } else if (payload == 'reflection:daily') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => JournalEditorSheet(
            date: DateTime.now(),
          ),
        ),
      );
    } else if (payload == 'focus:start') {
      setState(() => _currentIndex = 2);
    } else {
      setState(() => _currentIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
