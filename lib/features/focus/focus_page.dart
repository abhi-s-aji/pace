import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/pace_providers.dart';
import '../../core/theme/pace_colors.dart';
import '../../shared/widgets/completion_note_dialog.dart';

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> with TickerProviderStateMixin {
  int _selectedDurationMinutes = 25;
  String _sessionTitle = 'Focus Session';
  String? _linkedHabitId;

  bool _isRunning = false;
  bool _isPaused = false;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  static const _presetDurations = [15, 25, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedDurationMinutes * 60;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _elapsedSeconds = 0;
      _remainingSeconds = _selectedDurationMinutes * 60;
    });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _completeSession();
      } else {
        setState(() {
          _remainingSeconds--;
          _elapsedSeconds++;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isPaused = true);
  }

  void _resumeTimer() {
    setState(() => _isPaused = false);
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _completeSession();
      } else {
        setState(() {
          _remainingSeconds--;
          _elapsedSeconds++;
        });
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _elapsedSeconds = 0;
      _remainingSeconds = _selectedDurationMinutes * 60;
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    final actualMinutes = (_elapsedSeconds / 60).ceil();
    final state = ref.read(paceAppProvider);

    String? note;
    if (state.preferences.completionNotePreference == 'ask' && mounted) {
      final res = await CompletionNoteDialog.show(
        context,
        title: 'Focus: $_sessionTitle',
        subtitle: 'Log an optional reflection note for this $actualMinutes min session.',
      );
      note = res?.note;
      if (res?.dontAskAgain ?? false) {
        await ref.read(paceAppProvider.notifier).updatePreferences(
              state.preferences.copyWith(completionNotePreference: 'dont_ask'),
            );
      }
    }

    await ref.read(paceAppProvider.notifier).completeFocusSession(
          title: _sessionTitle,
          targetDurationMinutes: _selectedDurationMinutes,
          actualDurationMinutes: actualMinutes,
          habitId: _linkedHabitId,
          note: note,
        );

    if (mounted) {
      setState(() {
        _isRunning = false;
        _isPaused = false;
        _elapsedSeconds = 0;
        _remainingSeconds = _selectedDurationMinutes * 60;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Focus session completed — $actualMinutes min logged.'),
          backgroundColor: PaceColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _showCustomDurationDialog() async {
    int hours = _selectedDurationMinutes ~/ 60;
    int minutes = _selectedDurationMinutes % 60;
    if (hours == 0 && minutes == 0) minutes = 30;

    final hoursController = TextEditingController(text: hours.toString().padLeft(2, '0'));
    final minsController = TextEditingController(text: minutes.toString().padLeft(2, '0'));
    String? errorMessage;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Custom focus duration'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text('Hours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 65,
                            child: TextField(
                              controller: hoursController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      const Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: Text(':', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          const Text('Minutes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 65,
                            child: TextField(
                              controller: minsController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(fontSize: 12, color: PaceColors.error, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final h = int.tryParse(hoursController.text.trim()) ?? 0;
                    final m = int.tryParse(minsController.text.trim()) ?? 0;
                    final total = (h * 60) + m;
                    if (h < 0 || m < 0 || total <= 0) {
                      setDialogState(() {
                        errorMessage = 'Duration must be greater than 0 minutes.';
                      });
                      return;
                    }
                    if (total > 1440) {
                      setDialogState(() {
                        errorMessage = 'Duration cannot exceed 24 hours.';
                      });
                      return;
                    }
                    Navigator.of(ctx).pop(total);
                  },
                  child: const Text('Start'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result > 0) {
      setState(() {
        _selectedDurationMinutes = result;
        _remainingSeconds = result * 60;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paceAppProvider);

    final progress = _isRunning
        ? 1.0 - (_remainingSeconds / (_selectedDurationMinutes * 60))
        : 0.0;
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    final activeHabits = state.habits.where((h) => !h.isArchived).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Focus',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                      color: PaceColors.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Timer Display Ring
                Semantics(
                  label: _isRunning
                      ? '$minutes minutes $seconds seconds remaining'
                      : 'Timer stopped. Selected duration $_selectedDurationMinutes minutes.',
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) {
                      final scale = _isRunning && !_isPaused
                          ? 1.0 + (_pulseController.value * 0.02)
                          : 1.0;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              backgroundColor: PaceColors.lightBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isPaused ? PaceColors.accentGold : PaceColors.primary,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 2,
                                  color: PaceColors.lightTextPrimary,
                                ),
                              ),
                              if (_isRunning)
                                Text(
                                  _isPaused ? 'Paused' : 'Focusing...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isPaused
                                        ? PaceColors.accentGold
                                        : PaceColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Duration Presets (only when not running)
                if (!_isRunning) ...[
                  Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PaceColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ..._presetDurations.map((dur) {
                          final selected = _selectedDurationMinutes == dur;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Semantics(
                              label: '$dur minutes focus duration',
                              selected: selected,
                              button: true,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDurationMinutes = dur;
                                    _remainingSeconds = dur * 60;
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 52,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? PaceColors.primary.withValues(alpha: 0.15)
                                        : (PaceColors.lightSurfaceElevated),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? PaceColors.primary
                                          : (PaceColors.lightBorder),
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${dur}m',
                                      style: TextStyle(
                                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 14,
                                        color: selected
                                            ? PaceColors.primary
                                            : (PaceColors.lightTextSecondary),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Semantics(
                            label: 'Custom focus duration',
                            button: true,
                            child: InkWell(
                              onTap: _showCustomDurationDialog,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                height: 48,
                                decoration: BoxDecoration(
                                  color: !_presetDurations.contains(_selectedDurationMinutes)
                                      ? PaceColors.primary.withValues(alpha: 0.15)
                                      : PaceColors.lightSurfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: !_presetDurations.contains(_selectedDurationMinutes)
                                        ? PaceColors.primary
                                        : PaceColors.lightBorder,
                                    width: !_presetDurations.contains(_selectedDurationMinutes) ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    !_presetDurations.contains(_selectedDurationMinutes)
                                        ? '${_selectedDurationMinutes}m'
                                        : 'Custom',
                                    style: TextStyle(
                                      fontWeight: !_presetDurations.contains(_selectedDurationMinutes)
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 14,
                                      color: !_presetDurations.contains(_selectedDurationMinutes)
                                          ? PaceColors.primary
                                          : PaceColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Session Title Input
                  SizedBox(
                    width: 280,
                    child: TextField(
                      onChanged: (val) => _sessionTitle = val.isNotEmpty ? val : 'Focus Session',
                      decoration: const InputDecoration(
                        hintText: 'What are you focusing on?',
                        prefixIcon: Icon(Icons.edit_rounded, size: 18),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Link to Habit (optional)
                  if (activeHabits.isNotEmpty) ...[
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _linkedHabitId,
                        decoration: const InputDecoration(
                          hintText: 'Link to habit (optional)',
                          prefixIcon: Icon(Icons.link_rounded, size: 18),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No linked habit'),
                          ),
                          ...activeHabits.map((h) {
                            return DropdownMenuItem<String?>(
                              value: h.id,
                              child: Text(h.name, overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _linkedHabitId = val),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRunning) ...[
                      // Cancel button
                      OutlinedButton(
                        onPressed: _cancelTimer,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PaceColors.error,
                          side: BorderSide(color: PaceColors.error),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 16),
                      // Pause / Resume button
                      FilledButton.icon(
                        onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                        icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20),
                        label: Text(_isPaused ? 'Resume' : 'Pause'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _isPaused ? PaceColors.primary : PaceColors.accentGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Complete early
                      if (_elapsedSeconds > 60)
                        OutlinedButton(
                          onPressed: _completeSession,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PaceColors.success,
                            side: BorderSide(color: PaceColors.success),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                    ] else
                      SizedBox(
                        width: 200,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _startTimer,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text(
                            'Start Focus',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: PaceColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 40),

                // Recent Focus Sessions
                if (state.focusSessions.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Sessions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: PaceColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...state.focusSessions.take(5).map((session) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PaceColors.lightSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: PaceColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PaceColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.timer_rounded, size: 18, color: PaceColors.secondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                Text(
                                  session.date,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: PaceColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${session.actualDurationMinutes}m',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
