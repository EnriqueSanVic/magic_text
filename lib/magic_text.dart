//library magic_text;

import 'package:flutter/material.dart';

/// Author: Enrique Sánchez Vicente
class MagicText extends StatefulWidget {

  String data;
  String breakCharacter;
  TextStyle textStyle;
  StrutStyle? strutStyle;
  TextAlign? textAlign;
  Locale? locale;
  TextOverflow? overflow;
  int? maxLines;
  String? semanticsLabel;
  TextWidthBasis? textWidthBasis;
  TextHeightBehavior? textHeightBehavior;
  Color? selectionColor;

  bool useSmartSizeMode = false;
  bool useAsyncMode = false;

  int? minFontSize, maxFontSize;

  MagicText(this.data,
      {super.key,
        required this.breakCharacter,
        required this.useSmartSizeMode,
        required this.textStyle,
        required this.useAsyncMode,
        this.strutStyle,
        this.textAlign,
        this.locale,
        this.overflow,
        this.maxLines,
        this.semanticsLabel,
        this.textWidthBasis,
        this.textHeightBehavior,
        this.selectionColor,
        this.minFontSize,
        this.maxFontSize}) {

    assert(breakCharacter.length == 1,
    "The break character must be a string that only contains one character.");

    if(useSmartSizeMode){
      assert(
      minFontSize != null &&
          maxFontSize != null &&
          minFontSize! <= maxFontSize!,
      "When use smart size mode, the params maxSize and minSize are mandatory, an minSize shout be less or equal than maxSize.");
    }

  }

  @override
  State<StatefulWidget> createState() => MagicTextState();
}

class MagicTextState extends State<MagicText> {

  static const int NULL_CHAR_UNIT = 00;
  static const int SPACE_CODE_UNIT = 32;
  static const int END_OF_LINE_CODE_UNIT = 10;

  double? actualMaxWidth;
  TextStyle? _textStyle;

  @override
  void initState() {
    _textStyle = widget.textStyle;

    super.initState();
  }

  void _changeOptimizeTextStyle() {
    if (widget.useAsyncMode) {
          () async {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted) {
            setState(() {
              _optimizeTextStyle();
            });
          }
        });
      }();
    } else {
      _optimizeTextStyle();
    }
  }

  void _optimizeTextStyle() {
    int optimizedFontSize = _findMostOptimizedFontSize();
    _textStyle =
        widget.textStyle.copyWith(fontSize: optimizedFontSize.toDouble());
  }

  int _findMostOptimizedFontSize() {
    String resultString;
    int? minStepCharacters;
    int countBreakCharacters;
    int mostOptimizedTextSize = _textStyle!.fontSize!.toInt();
    TextStyle copyOfTextStyle;

    for (int i = widget.minFontSize!; i <= widget.maxFontSize!; i++) {
      copyOfTextStyle = widget.textStyle.copyWith(fontSize: i.toDouble());

      resultString = _processTextWrapEndOfLineCharacter(widget.data,
          copyOfTextStyle, actualMaxWidth!, widget.breakCharacter)!;

      countBreakCharacters =
          widget.breakCharacter.allMatches(resultString).length;

      if (minStepCharacters == null) {
        minStepCharacters = countBreakCharacters;
        mostOptimizedTextSize = i;
        continue;
      }

      if (countBreakCharacters <= minStepCharacters) {
        minStepCharacters = countBreakCharacters;
        mostOptimizedTextSize = i;
      }
    }

    return mostOptimizedTextSize;
  }

  String? _processTextWrapEndOfLineCharacter(String originalString,
      TextStyle style, double maxLineWidth, String stepChar) {

    List<int> originalStringUnicodeUnits = originalString.codeUnits;

    List<int> copyStringUnicodeUnits = [];

    List<int> resultStringChars = [];

    int resultIndex = 0;
    int auxChar;
    double nextStepLineWidth;
    double actualLineWidth = 0;
    bool haveEndOfLine;

    int stepUnicodeChar = stepChar.codeUnitAt(0);

    //replace originals \n characters for null characters
    for (int j = 0; j < originalStringUnicodeUnits.length; j++) {

      if (originalStringUnicodeUnits[j] == END_OF_LINE_CODE_UNIT) {
        copyStringUnicodeUnits.add(NULL_CHAR_UNIT);
        continue;
      }

      copyStringUnicodeUnits.add(originalStringUnicodeUnits[j]);

    }

    final double letterSpacing =
    (style.letterSpacing != null) ? style.letterSpacing! : 0;

    for (int i = 0; i < copyStringUnicodeUnits.length; i++) {

      nextStepLineWidth = actualLineWidth + _charSize(copyStringUnicodeUnits[i], style).width + letterSpacing;

      /**
       * if current character is a NULL character, then is a user string end of line
       */
      if (copyStringUnicodeUnits[i] == NULL_CHAR_UNIT) {
        resultStringChars.add(END_OF_LINE_CODE_UNIT);
        resultIndex++;
        actualLineWidth = 0;
        continue;
      }

      /**
       * if the width of the new string as a result of adding the current character
       * to be evaluated exceeds the maximum width.
       */
      if (nextStepLineWidth > maxLineWidth) {
        actualLineWidth = 0;

        //if the current character to be evaluated is a space, it is replaced by a end of line.
        if (copyStringUnicodeUnits[i] == SPACE_CODE_UNIT) {
          resultStringChars.add(END_OF_LINE_CODE_UNIT);
          resultIndex++;
          continue;
        }

        haveEndOfLine = false;

        if (copyStringUnicodeUnits[i - 1] == SPACE_CODE_UNIT) {
          resultStringChars.add(END_OF_LINE_CODE_UNIT);
          resultIndex++;
          haveEndOfLine = true;
        }

        ///save previous characater in auxiliar variable
        auxChar = resultStringChars[resultIndex - 1];

        /**
         * if the previous of the previous stepCharacter is space,
         * then replace previous character by an other space,
         * but if previous of the previous character if anyother character,
         * then a line break is occurring that cuts into a word, put stepCharacter.
         */
        resultStringChars[resultIndex - 1] =
        (resultStringChars[resultIndex - 2] == SPACE_CODE_UNIT)
            ? SPACE_CODE_UNIT
            : stepUnicodeChar;

        ///add end of line character

        if (!haveEndOfLine) {
          resultStringChars.add(END_OF_LINE_CODE_UNIT);
          resultIndex++;
        }

        /**
         * if the current character we want to put on the next line is a space, then it is omitted.
         * But if it is any other character it is placed at the beginning of the following line.
         */
        if (auxChar != SPACE_CODE_UNIT) {
          resultStringChars.add(auxChar);
          actualLineWidth += _charSize(auxChar, style).width;
          resultIndex++;
        }

        ///Add current character
        resultStringChars.add(copyStringUnicodeUnits[i]);
        resultIndex++;
        actualLineWidth += _charSize(copyStringUnicodeUnits[i], style).width;
      } else {
        if (i > 0 &&
            copyStringUnicodeUnits[i - 1] == END_OF_LINE_CODE_UNIT &&
            copyStringUnicodeUnits[i] == SPACE_CODE_UNIT) {
          continue;
        }

        resultStringChars.add(copyStringUnicodeUnits[i]);
        ++resultIndex;
        actualLineWidth = nextStepLineWidth;
      }
    }

    return String.fromCharCodes(resultStringChars);
  }

  /// Author: (Stack Overflow) Dmitry_Kovalov
  /// Stack overflow: https://stackoverflow.com/questions/52659759/how-can-i-get-the-size-of-the-text-widget-in-flutter
  Size _charSize(int unicodeChar, TextStyle style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: String.fromCharCode(unicodeChar), style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          ///only recalculate text style if change maxWidth of constraints
          if (actualMaxWidth != constraints.maxWidth) {
            actualMaxWidth = constraints.maxWidth;
            if (widget.useSmartSizeMode) {
              _changeOptimizeTextStyle();
            }
          }

          return Text(
              _processTextWrapEndOfLineCharacter(widget.data, _textStyle!,
                  actualMaxWidth!, widget.breakCharacter)!,
              style: _textStyle,
              strutStyle: widget.strutStyle,
              textAlign: widget.textAlign,
              textDirection: TextDirection.ltr,
              locale: widget.locale,
              softWrap: false,
              overflow: widget.overflow,
              textScaleFactor: 1.0,
              maxLines: widget.maxLines,
              semanticsLabel: widget.semanticsLabel,
              textWidthBasis: widget.textWidthBasis,
              textHeightBehavior: widget.textHeightBehavior,
              selectionColor: widget.selectionColor);
        });
  }
}
