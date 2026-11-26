import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../shared/app_widgets.dart';
import '../pricing/pricing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.api, required this.onSignOut, super.key});

  final ApiClient api;
  final Future<void> Function() onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Map<String, dynamic>>> _profileData;

  @override
  void initState() {
    super.initState();
    _profileData = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final results = await Future.wait([
      widget.api.get('/me'),
      widget.api.get('/subscription'),
    ]);
    return results
        .map(
          (item) => item is Map
              ? Map<String, dynamic>.from(item)
              : <String, dynamic>{},
        )
        .toList();
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _profileData = next);
    try {
      await next;
    } on Object {
      // The FutureBuilder shows the request error.
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari GoalPath?'),
        content: const Text('Kamu perlu login lagi untuk membuka data akun.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _profileData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorPanel(
            message: snapshot.error.toString(),
            onRetry: _reload,
          );
        }
        if (!snapshot.hasData) return const LoadingPanel();

        final profile = snapshot.data![0];
        final subscription = snapshot.data![1];
        final name = profile['name']?.toString().trim();
        final tier = subscription['tier']?.toString() ?? 'free';
        final isTrial = subscription['isTrial'] == true;
        final title = name == null || name.isEmpty ? 'GoalPath User' : name;
        final initial = title.isEmpty
            ? 'G'
            : title.substring(0, 1).toUpperCase();
        final status = tier == 'premium'
            ? (isTrial ? 'Premium trial' : 'Premium')
            : subscription['trialEligible'] == true
            ? 'Coba trial Premium'
            : 'Free';

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeading('Membership'),
                    const SizedBox(height: 6),
                    Text(
                      tier == 'premium'
                          ? (isTrial
                                ? 'Trial Premium sedang aktif.'
                                : 'Premium aktif di akunmu.')
                          : subscription['trialEligible'] == true
                          ? 'Akunmu memenuhi syarat untuk mencoba Premium.'
                          : 'Lihat harga dan fitur Premium.',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PricingScreen(api: widget.api),
                        ),
                      ),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Pricing dan trial Premium'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: const Text('Keluar'),
                  onTap: _confirmSignOut,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
