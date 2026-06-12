import 'package:flutter/material.dart';

/// M3 form-field entry point. Validation and state remain in the caller;
/// this module owns only the standard visual shell.
class AppTextField extends StatelessWidget {
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final TextInputType? keyboardType;
  final int? maxLines;

  const AppTextField({
    super.key,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.validator,
    this.onSaved,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: initialValue,
        validator: validator,
        onSaved: onSaved,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: labelText, hintText: hintText),
      );
}
