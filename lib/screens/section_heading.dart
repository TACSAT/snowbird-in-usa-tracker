// EN: A section title that screen readers can jump to. It is its own stop, so it is not
//     swallowed by the card or form around it.
// FR: Un titre de section auquel un lecteur d'écran peut sauter. C'est un arrêt à part,
//     pour ne pas être absorbé par la carte ou le formulaire qui l'entoure.

import 'package:flutter/material.dart';

class SectionHeading extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const SectionHeading(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        header: true,
        child: Text(text, style: style),
      );
}
