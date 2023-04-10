import 'dart:collection';

import 'package:flutter/material.dart';

/// Author: Enrique Sánchez Vicente
@immutable
class MagicText extends StatefulWidget {
  final String data;
  String? breakWordCharacter = '-';
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final Locale? locale;
  final TextOverflow? overflow;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  bool smartSizeMode = true;
  bool asyncMode = false;

  final int? minFontSize, maxFontSize;

  MagicText(this.data,
      {super.key,
      required this.smartSizeMode,
      required this.asyncMode,
      required this.textStyle,
      this.breakWordCharacter,
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
    assert(textStyle.fontSize != null,
        "The textStyle object must have a defined fontSize attribute.");

    assert(breakWordCharacter!.length == 1,
        "The break character must be a string that only contains one character.");

    if (smartSizeMode) {
      assert(
          minFontSize != null &&
              maxFontSize != null &&
              minFontSize! <= maxFontSize!,
          "When use smart size mode, the params maxSize and minSize are mandatory, an minSize shout be less or equal than maxSize.");
    }
  }

  @override
  State<StatefulWidget> createState() => _MagicTextState();
}

class _MagicTextState extends State<MagicText> {
  static const int NULL_CHAR_UNIT = 00;
  static const int SPACE_CODE_UNIT = 32;
  static const int END_OF_LINE_CODE_UNIT = 10;

  double? _actualMaxWidth;
  TextStyle? _textStyle;

  final Map<int, double> _charWidths = HashMap<int, double>();

  @override
  void initState() {
    _textStyle = widget.textStyle;

    super.initState();
  }

  void _changeOptimizeTextStyle() {
    if (widget.asyncMode) {
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

      resultString = _processTextWrapEndOfLineCharacter(
          widget.data, copyOfTextStyle, widget.breakWordCharacter!)!;

      countBreakCharacters =
          widget.breakWordCharacter!.allMatches(resultString).length;

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

  String? _processTextWrapEndOfLineCharacter(
      String originalString, TextStyle style, String stepChar) {
    List<int> originalStringUnicodeUnits = originalString.codeUnits;
    List<int> copyStringUnicodeUnits = [];
    List<int> resultStringChars = [];

    _charWidths.clear();

    int resultIndex = 0;
    int auxChar;
    double nextStepLineWidth;
    double actualLineWidth = 0;
    bool haveEndOfLine;

    int stepUnicodeChar = stepChar.codeUnitAt(0);

    ///replace originals \n characters for null characters
    for (int j = 0; j < originalStringUnicodeUnits.length; j++) {
      if (originalStringUnicodeUnits[j] == END_OF_LINE_CODE_UNIT) {
        copyStringUnicodeUnits.add(NULL_CHAR_UNIT);
        continue;
      }

      copyStringUnicodeUnits.add(originalStringUnicodeUnits[j]);
    }

    double? letterSpacing = style.letterSpacing;

    letterSpacing ??= 0;

    for (int i = 0; i < copyStringUnicodeUnits.length; i++) {
      nextStepLineWidth = actualLineWidth +
          _calculateCharWidth(copyStringUnicodeUnits[i], style) +
          letterSpacing;

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
      if (nextStepLineWidth > _actualMaxWidth!) {
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
          actualLineWidth += _calculateCharWidth(auxChar, style);
          resultIndex++;
        }

        ///Add current character
        resultStringChars.add(copyStringUnicodeUnits[i]);
        resultIndex++;
        actualLineWidth +=
            _calculateCharWidth(copyStringUnicodeUnits[i], style);
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

  double _calculateCharWidth(int unicodeChar, TextStyle style) {
    if (_charWidths.containsKey(unicodeChar)) {
      return _charWidths[unicodeChar]!;
    }

    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: String.fromCharCode(unicodeChar), style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);

    _charWidths[unicodeChar] = textPainter.size.width;

    return textPainter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      ///only recalculate text style if change maxWidth of constraints
      if (_actualMaxWidth != constraints.maxWidth) {
        _actualMaxWidth = constraints.maxWidth;
        if (widget.smartSizeMode) {
          _changeOptimizeTextStyle();
        }
      }

      return Text(
          _processTextWrapEndOfLineCharacter(
              widget.data, _textStyle!, widget.breakWordCharacter!)!,
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
