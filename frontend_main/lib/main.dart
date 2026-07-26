import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/logging.dart';
import 'core/router.dart';
import 'core/stroll/stroll_controller.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installAppLogging(); // compact, filtered console output
  runApp(const StrollingApp());
}

class StrollingApp extends StatefulWidget {
  const StrollingApp({super.key});

  @override
  State<StrollingApp> createState() => _StrollingAppState();
}

class _StrollingAppState extends State<StrollingApp> {
  late final GoRouter _router = createRouter();
  late final StrollController _stroll = StrollController();

  @override
  void dispose() {
    _stroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StrollScope(
      controller: _stroll,
      child: MaterialApp.router(
        title: 'Strolling',
        debugShowCheckedModeBanner: false,
        theme: buildStrollingTheme(),
        routerConfig: _router,
      ),
    );
  }
}
