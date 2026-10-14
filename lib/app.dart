import 'package:flutter/material.dart';

import 'features/home/presentation/pages/home_page.dart';

class SmartCartApp extends StatelessWidget {
  const SmartCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B8077)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
