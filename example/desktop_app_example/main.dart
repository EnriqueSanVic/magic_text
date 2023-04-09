import 'package:flutter/material.dart';
import 'package:magic_text/magic_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magic Text Windows Linux MacOs and Web.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'MagicTextDemo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MagicText magicText = MagicText(
    "The Flutter framework has been optimized to make rerunning build methods fast, so that you can just rebuild anything that needs updating rather than having to individually change instances of widgets.",
    breakWordCharacter: '-',
    smartSizeMode: true,
    asyncMode: true,
    minFontSize: 11,
    maxFontSize: 28,
    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        Expanded(
            child: Container(
          padding: const EdgeInsets.all(10),
          child: magicText,
        ))
      ],
    ));
  }
}
