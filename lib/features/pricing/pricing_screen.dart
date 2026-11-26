import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../shared/app_widgets.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({required this.api, super.key});
  final ApiClient api;

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  late Future<Map<String, dynamic>> _subscription;
  var _startingTrial = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _subscription = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await widget.api.get('/subscription');
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _subscription = next);
    try {
      await next;
    } on Object {
      // The FutureBuilder shows the request error.
    }
  }

  Future<void> _startTrial() async {
    setState(() {
      _startingTrial = true;
      _actionError = null;
    });
    try {
      await widget.api.request('/subscription/trial', method: 'POST');
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium trial berhasil dimulai.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _actionError = error.message);
    } finally {
      if (mounted) setState(() => _startingTrial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _subscription,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorPanel(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          if (!snapshot.hasData) return const LoadingPanel();

          final subscription = snapshot.data!;
          final premium = subscription['tier'] == 'premium';
          final eligible = subscription['trialEligible'] == true;
          final isTrial = subscription['isTrial'] == true;
          final days = subscription['premiumPeriodDays']?.toString() ?? '30';
          final trialDays = subscription['trialPeriodDays']?.toString() ?? '7';
          final price = _rupiah(subscription['premiumPriceIdr']);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            premium ? 'GoalPath Premium' : 'Premium',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        premium && isTrial
                            ? 'Trial Premium aktif'
                            : '$price / $days hari',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        premium
                            ? (isTrial
                                  ? 'Trial Premium sedang aktif.'
                                  : 'Langganan Premium sedang aktif.')
                            : eligible
                            ? 'Coba Premium gratis selama $trialDays hari.'
                            : 'Akses fitur Premium untuk mendukung perjalanan goal dan kebiasaanmu.',
                      ),
                      if (eligible && !premium) ...[
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _startingTrial ? null : _startTrial,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: _startingTrial
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Coba trial Premium'),
                        ),
                      ] else if (!premium) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Trial Premium sudah pernah digunakan pada akun ini.',
                        ),
                      ],
                      if (_actionError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _actionError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const SectionHeading('Yang termasuk dalam Premium'),
                const SizedBox(height: 8),
                const AppCard(
                  child: Column(
                    children: [
                      _FeatureRow(
                        Icons.chat_outlined,
                        'Kuota AI Coach lebih besar',
                      ),
                      Divider(height: 18),
                      _FeatureRow(
                        Icons.auto_awesome_outlined,
                        'Adaptasi kebiasaan',
                      ),
                      Divider(height: 18),
                      _FeatureRow(
                        Icons.insights_outlined,
                        'Future Self dan insight progres',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    );
  }
}

String _rupiah(dynamic value) {
  final amount = int.tryParse(value?.toString() ?? '') ?? 0;
  final digits = amount.toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = (end - 3).clamp(0, end);
    groups.insert(0, digits.substring(start, end));
  }
  return 'Rp ${groups.join('.')}';
}
