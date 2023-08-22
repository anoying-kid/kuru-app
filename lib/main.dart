import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kururin/firebase_options.dart';
import 'package:kururin/providers/auth_provider.dart';
import 'package:kururin/screens/kururin_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: AuthProvider(),
      child: const MaterialApp(
        home: KururinScreen()
      ),
    );
  }
}
