import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_initializer.dart';
import 'theme/arix_theme.dart';
import 'screens/node_radar_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();
  runApp(const ProviderScope(child: ArixApp()));
}

class ArixApp extends StatelessWidget {
  const ArixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARIX',
      debugShowCheckedModeBanner: false,
      theme: ArixTheme.darkTheme,
      home: const NodeRadarScreen(),
    );
  }
}
