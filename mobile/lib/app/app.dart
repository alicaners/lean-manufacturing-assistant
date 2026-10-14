import 'package:flutter/material.dart';

/// Root widget of the application.
class LeanAssistantApp extends StatelessWidget {
  const LeanAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Yalın Üretim Asistanı',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('Yalın Üretim Asistanı'),
        ),
      ),
    );
  }
}