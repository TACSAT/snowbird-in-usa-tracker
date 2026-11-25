// EN: Date and time dialogs. Flutter's own dialogs overflow at very large text on a
//     small phone, so the scale is capped inside them only; the rest of the app keeps
//     the user's full size.
// FR: Dialogues de date et d'heure. Ceux de Flutter débordent en très grand texte sur
//     un petit téléphone, donc l'échelle est plafonnée à l'intérieur seulement ; le
//     reste de l'appli garde la taille choisie.

import 'package:flutter/material.dart';

const double kPickerMaxTextScale = 2.0;

Widget _capped(BuildContext context, Widget? child) =>
    MediaQuery.withClampedTextScaling(
      maxScaleFactor: kPickerMaxTextScale,
      child: child ?? const SizedBox.shrink(),
    );

Future<DateTime?> pickDate(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
}) =>
    showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: _capped,
    );

Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial) =>
    showTimePicker(context: context, initialTime: initial, builder: _capped);
