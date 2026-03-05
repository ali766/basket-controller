import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'firebase_options.dart';
import 'controller_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Fullscreen immersive
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Keep screen on
  await WakelockPlus.enable();

  // Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BasketballApp());
}

class BasketballApp extends StatelessWidget {
  const BasketballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basketball Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const ControllerScreen(),
    );
  }
}
