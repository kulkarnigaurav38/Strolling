import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/router.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait-only, per the brief.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: FernwehApp()));
}

class FernwehApp extends ConsumerStatefulWidget {
  const FernwehApp({super.key});

  @override
  ConsumerState<FernwehApp> createState() => _FernwehAppState();
}

class _FernwehAppState extends ConsumerState<FernwehApp> {
  @override
  void initState() {
    super.initState();
    // permission_handler on first launch — camera + mic for the shoot.
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissions());
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return; // browser prompts on first camera use instead
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile) return;
    try {
      await [Permission.camera, Permission.microphone].request();
    } catch (_) {
      // Never block the app on a permission dialog failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Fernweh',
      debugShowCheckedModeBanner: false,
      theme: buildFernwehTheme(),
      routerConfig: router,
    );
  }
}
