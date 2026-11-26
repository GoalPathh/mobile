import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../shared/app_widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({required this.api, super.key});
  final ApiClient api;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<Map<String, dynamic>> _progress;

  @override
  void initState() {
    super.initState();
    _progress = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await widget.api.get('/progress/overview?range=last-7-days');
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _progress = next);
    try {
      await next;
    } on Object {
      // The FutureBuilder shows the request error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _progress,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorPanel(
            message: snapshot.error.toString(),
            onRetry: _reload,
          );
        }
        if (!snapshot.hasData) return const LoadingPanel();

        final data = snapshot.data!;
        final summary = data['summary'] is Map
            ? Map<String, dynamic>.from(data['summary'] as Map)
            : <String, dynamic>{};
        final goals = (data['goals'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final average = goals.isEmpty
            ? 0.0
            : goals
                      .map((goal) => _number(goal['progress']))
                      .reduce((a, b) => a + b) /
                  goals.length;

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeading('Progress dashboard'),
                    const SizedBox(height: 8),
                    Text(
                      'Rata-rata progres goal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${average.round()}%',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text('${goals.length} goals'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (average / 100).clamp(0.0, 1.0).toDouble(),
                      minHeight: 9,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  MetricCard(
                    label: 'Current Streak',
                    value: '${_value(summary['currentStreak'])} Days',
                    icon: Icons.local_fire_department_outlined,
                  ),
                  MetricCard(
                    label: 'Total XP',
                    value: '${_value(summary['totalXp'])} XP',
                    icon: Icons.bolt_outlined,
                  ),
                  MetricCard(
                    label: 'Completion Rate',
                    value: '${_value(summary['completionRate'])}%',
                    icon: Icons.donut_large_outlined,
                  ),
                  MetricCard(
                    label: 'Habits Completed',
                    value: _value(summary['habitsCompleted']),
                    icon: Icons.task_alt_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionHeading('Goal Performance'),
              const SizedBox(height: 4),
              Text(
                'Progress toward your goals',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              if (goals.isEmpty)
                const AppCard(
                  child: EmptyPanel(
                    title: 'Belum ada data progres',
                    message: 'Mulai goal dan kebiasaan untuk melihat perkembanganmu.',
                    icon: Icons.insights_outlined,
                  ),
                )
              else
                ...goals.map((goal) => _ProgressGoalCard(goal: goal)),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressGoalCard extends StatelessWidget {
  const _ProgressGoalCard({required this.goal});
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
          if (goal['status'] != null) ...[
            const SizedBox(height: 8),
            Text(goal['status'].toString()),
          ],
        ],
      ),
    );
  }
}

num _number(dynamic value) => num.tryParse(value?.toString() ?? '') ?? 0;
String _value(dynamic value) => _number(value).toString();
