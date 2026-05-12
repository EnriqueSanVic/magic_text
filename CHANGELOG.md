## 1.0.0

- Dart 3 / Flutter 3.12+ support: updated SDK and Flutter constraints.
- Replaced deprecated `textScaleFactor` with `textScaler: TextScaler.noScaling`.
- Added `richTextMode` parameter for `InlineSpan` support.
- Fixed `@immutable` compliance: all instance fields are now `final`.
- Added full public API documentation to meet pub.dev scoring requirements.
- Enabled `public_member_api_docs` lint rule.

## 0.0.1
Auto-responsive text widget that supports a multitude of parameters to control text rendering behaviour.

The main purpose of the Magic Text widget is to adapt to the available space in an elegant way, handling a character that allows to handle line breaks that cut words, remove unnecessary spaces and adapt the text size in such a way that there are as few word breaks as possible between a range of maximum and minimum sizes passed by parameter. The text rendering task can be done synchronously and asynchronously. It is also possible to parameterize most of the attributes used in a Text widget.

## 0.0.2
Auto-responsive text widget that supports a multitude of parameters to control text rendering behaviour.

The main purpose of the Magic Text widget is to adapt to the available space in an elegant way, handling a character that allows to handle line breaks that cut words, remove unnecessary spaces and adapt the text size in such a way that there are as few word breaks as possible between a range of maximum and minimum sizes passed by parameter. The text rendering task can be done synchronously and asynchronously. It is also possible to parameterize most of the attributes used in a Text widget.

## 0.0.3
Performance improvements

Rendering performance improvements to speed up the widget.
