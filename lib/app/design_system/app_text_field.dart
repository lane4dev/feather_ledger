import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum AppFieldVariant { filled, search, inline, amount }

/// M3 form-field entry point. Validation and state remain in the caller;
/// this module owns only the standard visual shell.
class AppTextField extends StatelessWidget {
  final String? initialValue;

  /// For a field that is driven live rather than through a `Form`, such as a
  /// search box. Mutually exclusive with [initialValue] — `TextFormField`
  /// rejects holding both.
  final TextEditingController? controller;

  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;

  /// Fires on every keystroke. Use [onSaved] for a field that only reports
  /// when a form is submitted.
  final ValueChanged<String>? onChanged;

  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final bool floatingLabel;
  final AppFieldVariant variant;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    this.initialValue,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.style,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.prefixText,
    this.floatingLabel = false,
    this.variant = AppFieldVariant.filled,
    this.textInputAction,
  }) : assert(initialValue == null || controller == null,
            'Pass initialValue or controller, not both');

  const AppTextField.search(
      {Key? key,
      TextEditingController? controller,
      ValueChanged<String>? onChanged,
      String? hintText})
      : this(
            key: key,
            controller: controller,
            onChanged: onChanged,
            hintText: hintText,
            variant: AppFieldVariant.search);

  @override
  Widget build(BuildContext context) {
    final inline =
        variant == AppFieldVariant.inline || variant == AppFieldVariant.amount;
    final amount = variant == AppFieldVariant.amount;
    final textStyle = style ??
        (amount
            ? AppTypography.amountInput(context)
            : Theme.of(context).textTheme.bodyLarge);
    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      autofocus: autofocus,
      style: textStyle,
      textAlign: textAlign,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        prefixStyle: textStyle?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        hintStyle: textStyle?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        floatingLabelBehavior:
            floatingLabel ? FloatingLabelBehavior.always : null,
        filled: !inline,
        border: inline ? InputBorder.none : null,
        enabledBorder: inline ? InputBorder.none : null,
        focusedBorder: inline ? InputBorder.none : null,
        errorBorder: inline ? InputBorder.none : null,
        focusedErrorBorder: inline ? InputBorder.none : null,
        isDense: inline,
        contentPadding: amount
            ? EdgeInsets.zero
            : inline
                ? EdgeInsets.symmetric(vertical: context.metrics.rowInset)
                : null,
      ),
    );
  }
}
