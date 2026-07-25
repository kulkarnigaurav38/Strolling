import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/sample_business_dashboard.dart';

class BusinessStatsGrid extends StatelessWidget {
  const BusinessStatsGrid({super.key, required this.stats});

  final List<BusinessStat> stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = 8.0;
          final tileW = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: stats
                .map(
                  (stat) => SizedBox(
                    width: tileW,
                    child: _StatCard(stat: stat),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final BusinessStat stat;

  @override
  Widget build(BuildContext context) {
    final color = Color(stat.color.value);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(stat.background.value),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.4,
            ),
          ),
          Text(
            stat.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B6B80),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.trend,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
