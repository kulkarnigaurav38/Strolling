import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/media_storage.dart';
import '../../../core/models.dart';
import '../../../core/theme.dart';
import '../../../core/session/session_controller.dart';
import '../widgets/progress_pips.dart';
import '../widgets/shutter_button.dart';
import '../widgets/task_card.dart';

/// The one screen that uses real hardware. Live camera behind a Stack of shot
/// guidance; the shutter captures a photo or records a clip. If no camera is
/// available (web/desktop/CI) it degrades to a "mock capture" so the whole flow
/// still runs with zero setup.
class ShootScreen extends ConsumerStatefulWidget {
  const ShootScreen({super.key});

  @override
  ConsumerState<ShootScreen> createState() => _ShootScreenState();
}

class _ShootScreenState extends ConsumerState<ShootScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _cameraAvailable = false;
  bool _recording = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      // Drop it from build first so we never render a disposed controller.
      setState(() {
        _controller = null;
        _cameraAvailable = false;
      });
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('none', 'No cameras');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: true, // clips need sound
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraAvailable = true;
        _initializing = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraAvailable = false;
          _initializing = false;
        });
      }
    }
  }

  void _emit(Task task, String mediaUrl) {
    ref.read(sessionProvider.notifier).addCapture(
          Capture(taskId: task.id, mediaUrl: mediaUrl, kind: task.type),
        );
    // Router redirects to /interview on the status change.
  }

  // Real captures pass through the storage boundary (mock: identity).
  Future<void> _emitFile(Task task, String path) async {
    final url = await ref.read(mediaStorageProvider).uploadMedia(path);
    if (mounted) _emit(task, url);
  }

  Future<void> _onShutter(Task task) async {
    if (_busy) return;
    final ctrl = _controller;

    // No usable camera → mock capture keeps the flow moving.
    if (!_cameraAvailable || ctrl == null || !ctrl.value.isInitialized) {
      _emit(task, '');
      return;
    }

    if (task.type == TaskType.photo) {
      setState(() => _busy = true);
      try {
        final file = await ctrl.takePicture();
        await _emitFile(task, file.path);
      } catch (_) {
        _emit(task, '');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    // Clip: tap to start, tap to stop.
    if (!_recording) {
      try {
        await ctrl.startVideoRecording();
        setState(() => _recording = true);
      } catch (_) {
        _emit(task, '');
      }
    } else {
      setState(() => _busy = true);
      try {
        final file = await ctrl.stopVideoRecording();
        setState(() => _recording = false);
        await _emitFile(task, file.path);
      } catch (_) {
        setState(() => _recording = false);
        _emit(task, '');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final task = session.currentTask;
    if (task == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CameraLayer(
                controller: _controller,
                initializing: _initializing,
                available: _cameraAvailable,
              ),
              // top + bottom scrims for legibility over any footage
              const _Scrim(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ProgressPips(
                              total: session.tasks.length,
                              currentIndex: session.currentTaskIndex,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Shot ${session.currentTaskIndex + 1} of ${session.tasks.length}'
                          '${_recording ? '  •  ● REC' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _recording
                                ? const Color(0xFFEF4444)
                                : AppColors.muted,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TaskCard(task: task),
                      const SizedBox(height: 20),
                      ShutterButton(
                        isClip: task.type == TaskType.clip,
                        isRecording: _recording,
                        busy: _busy,
                        onTap: () => _onShutter(task),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _busy ? null : () => _emit(task, ''),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.7),
                        ),
                        child: const Text('skip (mock)'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraLayer extends StatelessWidget {
  const _CameraLayer({
    required this.controller,
    required this.initializing,
    required this.available,
  });

  final CameraController? controller;
  final bool initializing;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    if (available && ctrl != null && ctrl.value.isInitialized) {
      final preview = ctrl.value.previewSize;
      // previewSize is reported landscape; swap for a portrait cover fill.
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: preview?.height ?? 9,
          height: preview?.width ?? 16,
          child: CameraPreview(ctrl),
        ),
      );
    }

    // Fallback / initializing: warm placeholder so the overlay still reads well.
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.roomGlow),
      child: Center(
        child: initializing
            ? const CircularProgressIndicator(color: AppColors.amber)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('📷', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text(
                    'Camera unavailable — tap to mock the shot',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.55),
          ],
          stops: const [0.0, 0.22, 0.5, 1.0],
        ),
      ),
    );
  }
}
