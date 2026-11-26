import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../shared/app_widgets.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<Map<String, dynamic>> _today;
  final Set<String> _updatingHabits = {};

  @override
  void initState() {
    super.initState();
    _today = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final offset = -DateTime.now().timeZoneOffset.inMinutes;
    final data = await widget.api.get('/today?tzOffset=$offset');
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _today = next);
    try {
      await next;
    } on Object {
      // The FutureBuilder shows the request error.
    }
  }

  Future<void> _setCompleted(Map<String, dynamic> habit) async {
    final id = habit['id']?.toString();
    if (id == null || id.isEmpty || _updatingHabits.contains(id)) return;
    final completed = habit['completed'] != true;
    setState(() => _updatingHabits.add(id));
    try {
      await widget.api.request(
        '/habits/$id/completion',
        method: 'PUT',
        body: {
          'completed': completed,
          'completionDate': _localDate(DateTime.now()),
        },
      );
      await _reload();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _updatingHabits.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _today,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorPanel(
            message: snapshot.error.toString(),
            onRetry: _reload,
          );
        }
        if (!snapshot.hasData) return const LoadingPanel();

        final plan = snapshot.data!;
        final profile = plan['profile'] is Map
            ? Map<String, dynamic>.from(plan['profile'] as Map)
            : <String, dynamic>{};
        final summary = plan['summary'] is Map
            ? Map<String, dynamic>.from(plan['summary'] as Map)
            : <String, dynamic>{};
        final habits = (plan['habits'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        final goals = (plan['goals'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        final name = profile['name']?.toString().trim().split(' ').first ?? '';
        final completed = _number(summary['completedHabits']);
        final total = _number(summary['totalHabits']);
        final rate = _number(summary['completionRate']).clamp(0, 100) / 100;

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              Text(
                name.isEmpty ? 'Hari ini milikmu' : 'Hai, $name',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Satu langkah kecil tetap membawa kamu maju.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeading('Progress hari ini'),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$completed/$total',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text('kebiasaan selesai'),
                        ),
                        const Spacer(),
                        Text('${(rate * 100).round()}%'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: rate.toDouble(),
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 12),
                    Text('${_number(summary['activeGoals'])} goal aktif'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionHeading(
                'Kebiasaan hari ini',
                trailing: Text('$completed dari $total'),
              ),
              const SizedBox(height: 10),
              if (habits.isEmpty)
                const AppCard(
                  child: EmptyPanel(
                    title: 'Belum ada kebiasaan hari ini',
                    message: 'Tambahkan kebiasaan ke goal untuk mulai membangun rutinitas.',
                    icon: Icons.checklist_outlined,
                  ),
                )
              else
                ...habits.map((habit) {
                  final id = habit['id']?.toString() ?? '';
                  final isUpdating = _updatingHabits.contains(id);
                  final minutes = habit['duration']?.toString() ?? '0';
                  final goalTitle = habit['goalTitle']?.toString() ?? 'Goal';
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      onTap: isUpdating ? null : () => _setCompleted(habit),
                      leading: isUpdating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Checkbox(
                              value: habit['completed'] == true,
                              onChanged: (_) => _setCompleted(habit),
                            ),
                      title: Text(
                        habit['title']?.toString() ?? 'Kebiasaan',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: habit['completed'] == true
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text('$minutes menit • $goalTitle'),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              const SectionHeading('Goal performance'),
              const SizedBox(height: 10),
              if (goals.isEmpty)
                const AppCard(
                  child: EmptyPanel(
                    title: 'Belum ada goal',
                    message: 'Goal yang kamu buat akan muncul di sini.',
                    icon: Icons.flag_outlined,
                  ),
                )
              else
                ...goals.map((goal) => _GoalProgressCard(goal: goal)),
            ],
          ),
        );
      },
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  const _GoalProgressCard({required this.goal});

  final Map<String, dynamic> goal;

  @override
  Widget build(BuildContext context) {
    final progress = (_number(goal['progress']) / 100)
        .clamp(0.0, 1.0)
        .toDouble();
    return AppCard(
      margin: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal['title']?.toString() ?? 'Goal',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text('${(progress * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, minHeight: 7),
        ],
      ),
    );
  }
}

num _number(dynamic value) => num.tryParse(value?.toString() ?? '') ?? 0;

String _localDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
