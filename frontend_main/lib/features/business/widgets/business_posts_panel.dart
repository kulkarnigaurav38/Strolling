import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../data/sample_business_dashboard.dart';

class BusinessPostsPanel extends StatelessWidget {
  const BusinessPostsPanel({super.key, required this.posts});

  final List<BusinessPost> posts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'LIVE POSTS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.55,
            color: StrollingColors.mutedAlt,
          ),
        ),
        const SizedBox(height: 12),
        ...posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PostCard(post: post),
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final BusinessPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              post.thumbnailAsset,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 56,
                height: 56,
                color: StrollingColors.surfaceMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.handle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: StrollingColors.nearBlack,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      post.platform,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: StrollingColors.mutedAlt,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Metric(
                      icon: 'assets/images/business/eye_icon.svg',
                      value: post.views,
                    ),
                    const SizedBox(width: 12),
                    _Metric(
                      icon: 'assets/images/business/heart_icon.svg',
                      value: post.likes,
                    ),
                    const SizedBox(width: 12),
                    _Metric(
                      icon: 'assets/images/business/comment_icon.svg',
                      value: post.comments,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final String icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 11,
          height: 11,
          child: SvgPicture.asset(
            icon,
            width: 11,
            height: 11,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: StrollingColors.mutedAlt,
          ),
        ),
      ],
    );
  }
}
