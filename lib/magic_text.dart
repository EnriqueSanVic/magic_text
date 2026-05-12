/// Magic Text — auto-responsive Flutter text widget with intelligent word
/// wrapping and optional font size optimisation.
///
/// See [MagicText] for the main widget.
library magic_text;

import 'dart:collection';

import 'package:flutter/material.dart';

/// A Flutter widget that renders text with automatic word wrapping and
/// optional font size optimisation within a given container width.
///
/// [MagicText] calculates the exact pixel width of each character to
/// determine line breaks, inserting a [breakWordCharacter] when a word
/// must be split across lines.
///
/// When [magicSizeMode] is enabled the widget iterates font sizes between
/// [minFontSize] and [maxFontSize] to find the size that minimises the number
/// of word breaks, producing the most readable layout.
///
/// Supports both plain [String] text and rich [InlineSpan] content via the
/// [richTextMode] flag. Note that word wrapping and [magicSizeMode]
/// optimisation are not applied in [richTextMode].
///
/// Example:
/// ```dart
/// MagicText(
///   'Hello, World!',
///   textStyle: const TextStyle(fontSize: 24),
///   magicSizeMode: true,
///   minFontSize: 12,
///   maxFontSize: 24,
/// )
/// ```
@immutable
class MagicText extends StatefulWidget {
  /// The text content to display.
  ///
  /// Must be a [String] when [richTextMode] is `false` (the default), or an
  /// [InlineSpan] when [richTextMode] is `true`.
  final dynamic child;

  /// The character inserted at the point where a word is broken across two
  /// lines. Must be exactly one character long. Defaults to `'-'`.
  final String? breakWordCharacter;

  /// The base [TextStyle] used for rendering.
  ///
  /// Must have a non-null [TextStyle.fontSize]. When [magicSizeMode] is
  /// enabled the font size is treated as the starting reference, and the
  /// widget replaces it with the optimised size found between [minFontSize]
  /// and [maxFontSize].
  final TextStyle textStyle;

  /// Optional strut style applied to the underlying [Text] widget.
  final StrutStyle? strutStyle;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// The locale used to select region-specific glyphs.
  final Locale? locale;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// Maximum number of lines for the text to span.
  final int? maxLines;

  /// An alternative semantics label for screen readers.
  final String? semanticsLabel;

  /// Defines how to measure the width of the rendered text.
  final TextWidthBasis? textWidthBasis;

  /// Defines how the paragraph will apply [TextStyle.height] to the ascent of
  /// the first line and descent of the last line.
  final TextHeightBehavior? textHeightBehavior;

  /// The colour used for the selection highlight when the text is selected.
  final Color? selectionColor;

  /// When `true`, [child] must be an [InlineSpan] and the widget renders using
  /// [RichText]. Word wrapping and [magicSizeMode] are not applied in this
  /// mode. Defaults to `false`.
  final bool richTextMode;

  /// When `true`, the widget iterates font sizes from [minFontSize] to
  /// [maxFontSize] to find the size with the fewest word breaks.
  ///
  /// Both [minFontSize] and [maxFontSize] are required when this is `true`,
  /// and `minFontSize` must be ≤ `maxFontSize`. Has no effect when
  /// [richTextMode] is `true`. Defaults to `false`.
  final bool magicSizeMode;

  /// When `true`, font size optimisation is scheduled as a post-frame callback
  /// so it does not block the first frame. Defaults to `false`.
  ///
  /// Recommended when using wide [minFontSize]–[maxFontSize] ranges, as the
  /// optimisation loop can be expensive. The view loads first and [MagicText]
  /// updates once ready without blocking the main rendering thread.
  final bool asyncMode;

  /// Minimum font size tried during [magicSizeMode] optimisation.
  final int? minFontSize;

  /// Maximum font size tried during [magicSizeMode] optimisation.
  final int? maxFontSize;

  /// Creates a [MagicText] widget.
  ///
  /// The [textStyle] must have a non-null [TextStyle.fontSize].
  ///
  /// When [magicSizeMode] is `true`, both [minFontSize] and [maxFontSize] must
  /// be provided and `minFontSize` must be ≤ `maxFontSize`.
  ///
  /// When [richTextMode] is `true`, [child] must be an [InlineSpan];
  /// otherwise [child] must be a [String].
  MagicText(
    this.child, {
    super.key,
    required this.textStyle,
    this.breakWordCharacter = '-',
    this.magicSizeMode = false,
    this.asyncMode = false,
    this.richTextMode = false,
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
    this.maxFontSize,
  }) {
    assert(textStyle.fontSize != null,
        'The textStyle object must have a defined fontSize attribute');

    assert(
        breakWordCharacter != null && breakWordCharacter!.length == 1,
        'The break character must be a non-null string that only contains one character');

    if (magicSizeMode) {
      assert(
          minFontSize != null &&
              maxFontSize != null &&
              minFontSize! <= maxFontSize!,
          'When magicSizeMode is enabled, minFontSize and maxFontSize are required and minFontSize must be <= maxFontSize');
    }

    if (richTextMode) {
      assert(child is InlineSpan,
          'child must be an InlineSpan when richTextMode is true');
    } else {
      assert(child is String,
          'child must be a String when richTextMode is false; set richTextMode: true to use an InlineSpan');
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

  /// Cache for character widths — memoised to avoid re-measuring the same
  /// glyph repeatedly during the font size optimisation loop.
  final Map<int, double> _charWidths = HashMap<int, double>();

  @override
  void initState() {
    _textStyle = widget.textStyle;
    super.initState();
  }

  @override
  void didUpdateWidget(MagicText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textStyle != widget.textStyle) {
      _textStyle = widget.textStyle;
      _actualMaxWidth = null; // force re-optimisation on next build
    }
  }

  void _changeOptimizeTextStyle() {
    // execute not async mode
    if (!widget.asyncMode) {
      _optimizeTextStyle();
      return;
    }
    // execute async mode
    () async {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          setState(() {
            _optimizeTextStyle();
          });
        }
      });
    }();
  }

  void _optimizeTextStyle() {
    _textStyle = widget.textStyle
        .copyWith(fontSize: _findMostOptimizedFontSize().toDouble());
  }

  int _findMostOptimizedFontSize() {
    String resultString;
    int? minStepCharacters;
    int countBreakCharacters;
    int mostOptimizedTextSize = widget.minFontSize!;
    TextStyle copyOfTextStyle;

    for (int i = widget.minFontSize!; i <= widget.maxFontSize!; i++) {
      copyOfTextStyle = widget.textStyle.copyWith(fontSize: i.toDouble());

      resultString = _processTextWrapEndOfLineCharacter(
          widget.child as String, copyOfTextStyle, widget.breakWordCharacter!)!;

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
    final List<int> originalStringUnicodeUnits = originalString.codeUnits;
    final List<int> copyStringUnicodeUnits = [];
    final List<int> resultStringChars = [];

    final double letterSpacing = style.letterSpacing ?? 0;

    int resultIndex = 0;
    int auxChar;
    double nextStepLineWidth;
    double actualLineWidth = 0;
    bool haveEndOfLine;

    int stepUnicodeChar = stepChar.codeUnitAt(0);

    // Clear char widths cache
    _charWidths.clear();

    // Replace originals \n characters for NULL characters
    _replaceLineBreakCharsByNullChars(
        originalStringUnicodeUnits, copyStringUnicodeUnits);

    // Iterate each original text characters
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
        actualLineWidth += _calculateCharWidth(copyStringUnicodeUnits[i], style);
        continue;
      }

      //  If previous char is End of line and current char is space char, continue
      if (i > 0 &&
          copyStringUnicodeUnits[i - 1] == END_OF_LINE_CODE_UNIT &&
          copyStringUnicodeUnits[i] == SPACE_CODE_UNIT) {
        continue;
      }

      // Add current original character to result
      resultStringChars.add(copyStringUnicodeUnits[i]);
      ++resultIndex;
      actualLineWidth = nextStepLineWidth;
    }

    return String.fromCharCodes(resultStringChars);
  }

  void _replaceLineBreakCharsByNullChars(
      List<int> originalStringUnicodeUnits, List<int> copyStringUnicodeUnits) {
    for (int j = 0; j < originalStringUnicodeUnits.length; j++) {
      if (originalStringUnicodeUnits[j] == END_OF_LINE_CODE_UNIT) {
        copyStringUnicodeUnits.add(NULL_CHAR_UNIT);
        continue;
      }

      copyStringUnicodeUnits.add(originalStringUnicodeUnits[j]);
    }
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
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      if (_actualMaxWidth != constraints.maxWidth) {
        _actualMaxWidth = constraints.maxWidth;
        if (widget.magicSizeMode && !widget.richTextMode) {
          _changeOptimizeTextStyle();
        }
      }

      if (widget.richTextMode) {
        return RichText(
          text: widget.child as InlineSpan,
          textAlign: widget.textAlign ?? TextAlign.start,
          textDirection: TextDirection.ltr,
          locale: widget.locale,
          softWrap: true,
          overflow: widget.overflow ?? TextOverflow.clip,
          textScaler: TextScaler.noScaling,
          maxLines: widget.maxLines,
          textWidthBasis: widget.textWidthBasis ?? TextWidthBasis.parent,
          textHeightBehavior: widget.textHeightBehavior,
        );
      }

      return Text(
          _processTextWrapEndOfLineCharacter(
              widget.child as String, _textStyle!, widget.breakWordCharacter!)!,
          style: _textStyle,
          strutStyle: widget.strutStyle,
          textAlign: widget.textAlign,
          textDirection: TextDirection.ltr,
          locale: widget.locale,
          softWrap: false,
          overflow: widget.overflow,
          textScaler: TextScaler.noScaling,
          maxLines: widget.maxLines,
          semanticsLabel: widget.semanticsLabel,
          textWidthBasis: widget.textWidthBasis,
          textHeightBehavior: widget.textHeightBehavior,
          selectionColor: widget.selectionColor);
    });
  }
}
