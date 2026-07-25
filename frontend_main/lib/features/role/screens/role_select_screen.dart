import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/onboarding_args.dart';
import '../../../core/user_role.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelect(UserRole role) {
    final args = OnboardingArgs(role: role);
    switch (role) {
      case UserRole.creator:
        context.push(AppRoutes.auth, extra: args);
      case UserRole.business:
        context.push(AppRoutes.city, extra: args);
      case UserRole.browse:
        context.push(AppRoutes.city, extra: args);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE8DF),
              StrollingColors.background,
              Color(0xFFF2EFE8),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      'Strolling',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.96,
                        color: StrollingColors.ink,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Who\'s walking with us today?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        height: 1.4,
                        color: StrollingColors.muted,
                      ),
                    ),
                    const Spacer(flex: 2),
                    ...UserRole.values.asMap().entries.map((entry) {
                      final i = entry.key;
                      final role = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: i == 2 ? 0 : 12),
                        child: _RoleOption(
                          role: role,
                          onTap: () => _onSelect(role),
                        ),
                      );
                    }),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatefulWidget {
  const _RoleOption({
    required this.role,
    required this.onTap,
  });

  final UserRole role;
  final VoidCallback onTap;

  @override
  State<_RoleOption> createState() => _RoleOptionState();
}

class _RoleOptionState extends State<_RoleOption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  IconData get _icon => switch (widget.role) {
        UserRole.creator => Icons.camera_alt_outlined,
        UserRole.business => Icons.storefront_outlined,
        UserRole.browse => Icons.explore_outlined,
      };

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1,
      value: 1,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _press,
      child: Material(
        color: StrollingColors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _press.reverse(),
          onTapCancel: () => _press.forward(),
          onTapUp: (_) => _press.forward(),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: StrollingColors.border),
              boxShadow: [
                BoxShadow(
                  color: StrollingColors.ink.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          StrollingColors.primary,
                          StrollingColors.primaryMid,
                        ],
                      ),
                    ),
                    child: Icon(_icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.role.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: StrollingColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.role.description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            height: 1.35,
                            color: StrollingColors.mutedAlt,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: StrollingColors.muted.withValues(alpha: 0.7),
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
