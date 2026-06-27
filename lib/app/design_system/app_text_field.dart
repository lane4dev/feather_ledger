import 'package:flutter/material.dart';

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
  }) : assert(initialValue == null || controller == null,
            'Pass initialValue or controller, not both');

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: initialValue,
        controller: controller,
        validator: validator,
        onSaved: onSaved,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: labelText, hintText: hintText),
      );
}
