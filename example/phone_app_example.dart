import 'dart:async';

import 'package:flutter/material.dart';
import 'package:magic_text/magic_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Magic Text Windows Linux MacOs and Web.',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'MagicTextDemo'),
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
  static const double HORIZONTAL_CONTAINER_MARGIN = 20;

  double? originalWidth;
  double? containerWidth;
  bool isGrowing = true;
  int step = 1;

  @override
  void initState() {
    super.initState();
  }

  void _initAnimation() {
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((timeStamp) {
      Timer.periodic(const Duration(milliseconds: 3500), (timer) {
        if (isGrowing) {
          _updateContainerWidth(++step);
          if (step >= 4) isGrowing = false;
        } else {
          _updateContainerWidth(--step);
          if (step <= 1) isGrowing = true;
        }
      });
    });
  }

  void _updateContainerWidth(int step) {
    setState(() {
      containerWidth = (step / 4) * originalWidth!;
    });

    print(
        'step $step, originalWidth: $originalWidth , containerWidth: $containerWidth');
  }

  @override
  Widget build(BuildContext context) {
    containerWidth ??=
        MediaQuery.of(context).size.width - HORIZONTAL_CONTAINER_MARGIN * 2;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 40, 40, 40),
        body: SafeArea(
      child: Column(
        children: [
          Expanded(
              child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.decelerate,
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.fromLTRB(HORIZONTAL_CONTAINER_MARGIN, 40,
                HORIZONTAL_CONTAINER_MARGIN, 30),
            width: containerWidth,
            decoration: const BoxDecoration(
                color: Color.fromARGB(255, 242, 25, 105),
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: LayoutBuilder(
              builder: (BuildContext, BoxConstraints) {
                if (originalWidth == null) {
                  originalWidth =
                      BoxConstraints.maxWidth + HORIZONTAL_CONTAINER_MARGIN;
                  _initAnimation();
                }

                MagicText magicText = MagicText(
                  "The Flutter framework has been optimized to make rerunning build methods fast, so that you can just rebuild anything that needs updating rather than having to individually change instances of widgets.",
                  breakCharacter: '-',
                  useSmartSizeMode: true,
                  useAsyncMode: true,
                  minFontSize: 19,
                  maxFontSize: 26,
                  textStyle: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                );

                return magicText;
              },
            ),
          ))
        ],
      ),
    ));
  }
}
