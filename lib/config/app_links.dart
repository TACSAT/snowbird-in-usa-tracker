// EN: External web links for the Feedback, Donate, and Source buttons (FR-16).
//     They open in the OS browser via url_launcher — the app itself sends nothing
//     and needs no INTERNET permission (the browser makes the request, not us).
//
//     ⚠ FEEDBACK AND DONATE ARE PLACEHOLDERS. Before release, the project owner must replace each
//     value with the real endpoint (a no-backend feedback form or the public GitHub
//     Issues URL for feedback; a PayPal.me / Ko-fi link for donations).
//     All three are gathered here, in one file, so there is a
//     single place to set them and nothing is hard-coded in a widget.
//
// FR: Liens web externes pour les boutons Commentaires, Don et Source (FR-16). Ils
//     s'ouvrent dans le navigateur de l'OS via url_launcher — l'appli elle-même
//     n'envoie rien et n'a pas besoin de la permission INTERNET (c'est le navigateur
//     qui fait la requête, pas nous).
//
//     ⚠ COMMENTAIRES ET DON SONT DES ESPACES RÉSERVÉS. Avant la publication, le propriétaire du
//     projet doit remplacer chaque valeur par le vrai point de terminaison (un
//     formulaire de commentaires sans serveur ou l'URL publique des Issues GitHub
//     pour les commentaires ; un lien PayPal.me / Ko-fi pour les dons). Les trois
//     sont regroupés ici, dans un seul fichier,
//     pour qu'il y ait un seul endroit où les définir et que rien ne soit codé en
//     dur dans un widget.

abstract final class AppLinks {
  // EN: Placeholder — replace with the real feedback destination.
  // FR: Espace réservé — remplacer par la vraie destination de commentaires.
  static const String feedbackUrl = 'https://veidimadur.ca/snowbird/feedback';

  // EN: Placeholder — replace with the real donation destination.
  // FR: Espace réservé — remplacer par la vraie destination de don.
  static const String donateUrl = 'https://veidimadur.ca/snowbird/support';

  // EN: The public source-code repository (final, not a placeholder).
  // FR: Le dépôt public du code source (définitif, pas un espace réservé).
  static const String sourceUrl =
      'https://github.com/TACSAT/snowbird-in-usa-tracker';
}
