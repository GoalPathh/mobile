import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../shared/app_widgets.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({required this.api, super.key});
  final ApiClient api;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late Future<Map<String, dynamic>> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await widget.api.get('/goals/dashboard');
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _dashboard = next);
    try {
      await next;
    } on Object {
      // The FutureBuilder shows the request error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboard,
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

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              Text(
                'Tujuanmu, satu langkah demi satu langkah.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  MetricCard(
                    label: 'Active Goals',
                    value: _value(summary['activeGoals']),
                    icon: Icons.flag_outlined,
                  ),
                  MetricCard(
                    label: 'Daily Habits',
                    value: _value(summary['totalHabits']),
                    icon: Icons.checklist_outlined,
                  ),
                  MetricCard(
                    label: 'Focus Time',
                    value: '${_value(summary['totalMinutes'])}m',
                    icon: Icons.schedule,
                  ),
                  MetricCard(
                    label: 'Milestones Done',
                    value: _value(summary['completedMilestones']),
                    icon: Icons.emoji_events_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SectionHeading('Goals', trailing: Text('${goals.length} total')),
              const SizedBox(height: 10),
              if (goals.isEmpty)
                const AppCard(
                  child: EmptyPanel(
                    title: 'Belum ada goal',
                    message: 'Goal yang kamu buat akan tersimpan dan tampil di sini.',
                    icon: Icons.flag_outlined,
                  ),
                )
              else
                ...goals.map((goal) => _GoalCard(goal: goal)),
            ],
          ),
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final Map<String, dynamic> goal;

  @override
  Widget build(BuildContext context) {
    final percent = (_number(goal['progress']) / 100)
        .clamp(0.0, 1.0)
        .toDouble();
    final status = goal['status']?.toString() ?? 'On Track';
    final milestones = _value(goal['completedMilestoneCount']);
    final totalMilestones = _value(goal['milestoneCount']);
    final daysLeft = goal['daysLeft'];

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  goal['title']?.toString() ?? 'Goal',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(percent * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: percent, minHeight: 8),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _DetailLabel(Icons.track_changes, status),
              _DetailLabel(
                Icons.flag_outlined,
                '$milestones/$totalMilestones milestones',
              ),
              if (daysLeft is num)
                _DetailLabel(
                  Icons.calendar_today_outlined,
                  '$daysLeft days left',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  const _DetailLabel(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 5),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

num _number(dynamic value) => num.tryParse(value?.toString() ?? '') ?? 0;
String _value(dynamic value) => _number(value).toString();
