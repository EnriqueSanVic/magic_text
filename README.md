# Magic Text

Auto-responsive text widget that supports a multitude of parameters to control text rendering behaviour.

The main purpose of the Magic Text widget is to adapt to the available space in an elegant way, handling a character that allows to handle line breaks that cut words, remove unnecessary spaces and adapt the text size in such a way that there are as few word breaks as possible between a range of maximum and minimum sizes passed by parameter. The text rendering task can be done synchronously and asynchronously. It is also possible to parameterize most of the attributes used in a Text widget.

## Features

<img src="https://github.com/EnriqueSanVic/magic_text/blob/main/example/img/windows_magic_text_example.gif" width="500px" height="264px">
<br />

## Getting started

### Installing

```yaml
dependencies:
  magic_text: ^0.0.1
```

###Import package in 

```dart
import 'package:magic_text/magic_text.dart';
```
## Usage

```dart

//Instance a MagicText widget and save in a constant.
const MagicText magicText = MagicText(
  "The Flutter framework has been optimized to make rerunning build methods fast, so that you can just rebuild anything that needs updating rather than having to individually change instances of widgets.",
  breakCharacter: '-',
  useSmartSizeMode: true,
  useAsyncMode: true,
  minFontSize: 20,
  maxFontSize: 40,
  maxLines: 4,
  textStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold
  ),
);

```

## Additional information


Developed By Enrique Sánchez Vicente.
