// EN: Who makes the app and what it is called. The name is provisional: to change it,
//     change it here and in the two native labels (AndroidManifest.xml and Info.plist);
//     identity_test.dart fails until all three agree.
//     NOT part of the name, and never to follow it: storage keys (renaming them would
//     lose users' trips), application and bundle IDs, the package and repository names.
// FR: Qui fait l'appli et comment elle s'appelle. Le nom est provisoire : pour le changer,
//     le changer ici et dans les deux libellés natifs (AndroidManifest.xml et Info.plist) ;
//     identity_test.dart échoue tant que les trois ne concordent pas.
//     Ne font PAS partie du nom et ne doivent jamais le suivre : les clés de stockage (les
//     renommer perdrait les séjours), les identifiants d'appli, les noms du paquet et du
//     dépôt.
abstract final class AppIdentity {
  static const String name = 'SENALOVIRA';
  static const String maker = 'teagarden.net';
}
