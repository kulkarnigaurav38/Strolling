import 'package:flutter/material.dart';

import '../theme.dart';

/// Two-step onboarding progress (city → interests).
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.step});

  /// 1-based step index (1 or 2).
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Segment(active: step >= 1)),
        const SizedBox(width: 6),
        Expanded(child: _Segment(active: step >= 2)),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 4,
      decoration: BoxDecoration(
        color: active
            ? StrollingColors.primaryDeep
            : StrollingColors.primaryDeep.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
