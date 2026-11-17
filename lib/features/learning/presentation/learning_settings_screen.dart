import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/study_reminder_providers.dart';
import 'package:strategy_workbench/features/learning/domain/study_reminder.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class LearningSettingsScreen extends ConsumerStatefulWidget {
  const LearningSettingsScreen({super.key});

  @override
  ConsumerState<LearningSettingsScreen> createState() =>
      _LearningSettingsScreenState();
}

class _LearningSettingsScreenState
    extends ConsumerState<LearningSettingsScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _setEnabled(bool value, {required bool korean}) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result =
        await ref.read(studyReminderProvider.notifier).setEnabled(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _message = switch (result) {
        StudyReminderToggleResult.permissionDenied =>
          StudyReminderCopy.permissionDenied(korean: korean),
        StudyReminderToggleResult.scheduleFailed =>
          StudyReminderCopy.scheduleFailed(korean: korean),
        _ => null,
      };
    });
  }

  Future<void> _pickTime(StudyReminderSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Color(0xFF0F172A),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    await ref.read(studyReminderProvider.notifier).setTime(
          hour: picked.hour,
          minute: picked.minute,
        );
  }

  @override
  Widget build(BuildContext context) {
    final korean = (ref.watch(languageProvider).value ?? 'en') == 'ko';
    final settings = ref.watch(studyReminderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(StudyReminderCopy.screenTitle(korean: korean)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: settings.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
        error: (error, _) => Center(
          child: Text('$error', style: const TextStyle(color: Colors.white70)),
        ),
        data: (value) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const Key('study-reminder-switch'),
                        value: value.enabled,
                        activeThumbColor: const Color(0xFF10B981),
                        title: Text(
                          StudyReminderCopy.toggleTitle(korean: korean),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          StudyReminderCopy.toggleSubtitle(korean: korean),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        onChanged: _busy
                            ? null
                            : (next) => _setEnabled(next, korean: korean),
                      ),
                      ListTile(
                        key: const Key('study-reminder-time'),
                        enabled: !_busy,
                        title: Text(
                          StudyReminderCopy.timeLabel(korean: korean),
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Text(
                          formatStudyReminderTime(value.hour, value.minute),
                          style: const TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onTap: () => _pickTime(value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                StudyReminderCopy.timeHelp(korean: korean),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                StudyReminderCopy.rebootNote(korean: korean),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  key: const Key('study-reminder-message'),
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
