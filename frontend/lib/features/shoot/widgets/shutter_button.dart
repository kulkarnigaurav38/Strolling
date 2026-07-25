import 'package:flutter/material.dart';

/// The capture control. A white shutter for photos; a red record button that
/// morphs to a stop-square while a clip is recording.
class ShutterButton extends StatelessWidget {
  const ShutterButton({
    super.key,
    required this.isClip,
    required this.isRecording,
    required this.onTap,
    this.busy = false,
  });

  final bool isClip;
  final bool isRecording;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final innerColor = isClip ? const Color(0xFFEF4444) : Colors.white;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.9), width: 4),
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isRecording ? 30 : 60,
                  height: isRecording ? 30 : 60,
                  decoration: BoxDecoration(
                    color: innerColor,
                    borderRadius: BorderRadius.circular(isRecording ? 8 : 999),
                  ),
                ),
        ),
      ),
    );
  }
}
