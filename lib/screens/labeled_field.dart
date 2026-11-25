// EN: A text field whose label sits above it as ordinary text. Material's built-in
//     label is one line and is cut off at large sizes or in longer languages; this one
//     wraps (NFR-5). The two are merged so screen readers announce them together.
// FR: Un champ de texte dont l'étiquette se place au-dessus en texte ordinaire. Celle
//     de Material tient sur une ligne et se fait couper en grande taille ou dans les
//     langues plus longues ; celle-ci passe à la ligne (NFR-5). Les deux sont fusionnées
//     pour que les lecteurs d'écran les annoncent ensemble.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int? maxLength;
  final int maxLines;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLength,
    this.maxLines = 1,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            TextFormField(
              controller: controller,
              maxLength: maxLength,
              maxLines: maxLines,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              // EN: Help and error text wraps instead of being cut off at large sizes.
              // FR: Les textes d'aide et d'erreur passent à la ligne au lieu d'être
              //     coupés en grande taille.
              decoration: InputDecoration(
                helperText: helper,
                helperMaxLines: 20,
                errorMaxLines: 20,
                counterText: '',
              ),
            ),
          ],
        ),
      );
}
