import 'package:flutter/material.dart';
import 'HomePage.dart'; // Import de la page Home

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Desktop App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(), // Utilisation de la page Home importée
    );
  }
}
