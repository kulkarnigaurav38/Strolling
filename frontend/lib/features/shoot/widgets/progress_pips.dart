import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// n/5 shot progress. Filled = in the can, ringed = current, dim = to come.
class ProgressPips extends StatelessWidget {
  const ProgressPips({
    super.key,
    required this.total,
    required this.currentIndex,
  });

  final int total;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i < currentIndex;
        final active = i == currentIndex;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: done
                  ? AppColors.amber
                  : active
                      ? null
                      : AppColors.border,
              gradient: active
                  ? LinearGradient(colors: [
                      AppColors.amber,
                      AppColors.amber.withValues(alpha: 0.25),
                    ])
                  : null,
              border: active
                  ? Border.all(color: AppColors.amber.withValues(alpha: 0.5))
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
