import 'package:flutter/material.dart';

import 'login.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy Smart Labels',
      theme: ThemeData.light(),
      home: const LoginPage(),
    );
  }
}
