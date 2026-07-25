import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/copy.dart';
import '../../../core/seed.dart';
import '../../../core/theme.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/primary_button.dart';

class BriefScreen extends ConsumerStatefulWidget {
  const BriefScreen({super.key});

  @override
  ConsumerState<BriefScreen> createState() => _BriefScreenState();
}

class _BriefScreenState extends ConsumerState<BriefScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await ref.read(apiClientProvider).generateTasks(kBusiness);
      ref.read(sessionProvider.notifier).startShoot(tasks);
      // Router redirects to /shoot on the status change.
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = "Couldn't reach the Regisseur. Try again.";
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Pill(label: '🎬 Fernweh'),
                        const SizedBox(height: 20),
                        const Text(
                          Copy.tagline,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TODAY'S SET",
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                kBusiness.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                kBusiness.venue,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.muted,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.amber.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.amber
                                          .withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  kBusiness.incentive,
                                  style: const TextStyle(
                                    color: AppColors.amber,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: const [
                            Pill(label: '5 quick shots'),
                            SizedBox(width: 10),
                            Text('·', style: TextStyle(color: AppColors.muted)),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'guided by der Regisseur',
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFF87171), fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                  PrimaryButton(
                    label: _loading ? 'Setting the scene…' : Copy.briefCta,
                    busy: _loading,
                    onPressed: _loading ? null : _start,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
