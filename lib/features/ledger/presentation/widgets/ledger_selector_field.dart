import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

import '../theme/ledger_theme.dart';

/// The value column of a form row, with its field name in front of it and its
/// error under it.
///
/// It draws and nothing else: what happens when the row is tapped — the
/// ripple, the chevron, the picker — belongs to the row
/// ([LedgerFormRow.onTap]), which is why the tap covers the row's icon too.
///
/// The name occupies a fixed column ([labelWidth]) so that every value begins
/// at the same x down a whole form. The width is measured once per form from
/// the names that form can show ([LedgerTheme.formLabelWidth]) rather than
/// here, because one row cannot know what its siblings say.
class LedgerSelectorField extends StatelessWidget {
  /// A persistent field name. When provided, [text] is rendered as the
  /// current value rather than replacing the field's meaning.
  final String? label;

  /// The width of the name's column, shared by every row of the form. Only
  /// meaningful with a [label].
  final double? labelWidth;

  final String text;
  final TextStyle? textStyle;
  final String? errorText;

  /// An optional 22–24 dp value icon drawn immediately before the text.
  final Widget? leading;

  /// Pins the value to the row's trailing edge, against the chevron. The note
  /// field keeps its value on the leading edge because it is an input.
  final bool alignEnd;

  const LedgerSelectorField({
    super.key,
    this.label,
    this.labelWidth,
    required this.text,
    this.textStyle,
    this.errorText,
    this.leading,
    this.alignEnd = false,
  }) : assert(label == null || labelWidth != null,
            'a labelled field needs the column width its form measured');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.metrics.rowInset),
          child: Row(
            children: [
              if (label != null) ...[
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    label!,
                    // One line, always. A name is not a sentence, and a name
                    // that wrapped would push the row's height around. What
                    // gives when there is not enough room is the value, which
                    // is allowed to ellipsize.
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: LedgerTheme.formLabelGap),
              ],
              Expanded(
                child: alignEnd
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (leading != null) ...[
                              leading!,
                              SizedBox(width: context.spacing.sm),
                            ],
                            Flexible(
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyle ?? theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle ?? theme.textTheme.bodyLarge,
                      ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
      ],
    );
  }
}
