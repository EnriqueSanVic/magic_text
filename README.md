# Magic Text 🔤

Auto-responsive text widget that supports a multitude of parameters to control text rendering behaviour.

The main purpose of the Magic Text widget is to adapt to the available space in an elegant way, handling a character that allows to handle line breaks that cut words, remove unnecessary spaces and adapt the text size in such a way that there are as few word breaks as possible between a range of maximum and minimum sizes passed by parameter. The text rendering task can be done synchronously and asynchronously. It is also possible to parameterize most of the attributes used in a Text widget.

## Examples

<p align="center">
  <img src="https://github.com/EnriqueSanVic/magic_text/blob/main/example/img/phone_app_magic_text_example.gif" width="126px" height="280px">
  <img src="https://github.com/EnriqueSanVic/magic_text/blob/main/example/img/windows_magic_text_example.gif" width="500px" height="264px">
</p>

## Features

<b>smartSizeMode</b>: Enable or disable smart text size mode so that the widget chooses the appropriate text size from the given maxSize - minSize range so that there are the fewest number of word breaks in line breaks.

<b>asyncMode</b>: Allows the widget to be re-rendered asynchronously, this means that it is not the main rendering thread of the Flutter framework that builds the element, which causes the widget to update after all other GUI elements are loaded, this can speed up the loading time of a view. This mode is recommended to be enabled when using wide text size ranges between maxSize - minSize in smartSizeMode, because it can cause slow rendering times, if asynchronous mode is enabled, the view will load first and then the MagicText widget will be rendered when ready without blocking the main rendering thread optimising the loading time.

## Getting started

### Installing

Paste this line in dependencies section of pubspec.yaml file and run ```flutter pub get``` command.
```yaml
dependencies:
  magic_text: ^0.0.1
```

### Import 

```dart
import 'package:magic_text/magic_text.dart';
```
## Usage

Instance MagicText widget:
```dart

//Instance a MagicText widget and save in a constant.
const MagicText magicText = MagicText(
  "The Flutter framework has been optimized to make rerunning build methods fast, so that you can just rebuild anything that needs updating rather than having to individually change instances of widgets.",
  breakCharacter: '-',
  smartSizeMode: true,
  asyncMode: true,
  minFontSize: 20,
  maxFontSize: 40,
  textStyle: const TextStyle(
      fontSize: 20, //It is mandatory that the textStyle has a fontsize.
      fontWeight: FontWeight.bold
  ),
);

```

## Additional information
Developed By Enrique Sánchez Vicente.
