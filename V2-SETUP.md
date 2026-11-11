# NEO ARCADE — édition réunifiée V1 + V2

Cette édition rassemble les jeux et la progression de la V1 avec les nouveaux jeux et options de la V2.

## Jeux
- REACTION — mesurer son temps de réaction.
- MEMORY — retrouver les paires.
- NUMBER RUSH — cliquer les nombres dans l'ordre.
- NEON SNAKE — Snake avec commandes clavier et tactiles.
- NEON AIM — viser les cibles pendant le temps imparti.
- BATTLE LOCAL — duel à deux joueurs sur le même appareil.

## Progression et personnalisation
- XP, niveaux, succès et records locaux.
- 10 avatars et 10 thèmes.
- Effet RGB activable.
- Fond d'écran personnalisé enregistré sur l'appareil.
- Tableau personnel de records.

## Installation
Le projet est une PWA. Héberge-le en HTTPS (GitHub Pages convient), ouvre-le une première fois en ligne puis installe-le depuis ton navigateur. Les données de progression et préférences sont stockées localement dans le navigateur : elles ne sont pas synchronisées entre appareils.

## Limites actuelles
- Battle en ligne entre deux appareils : pas encore développé.
- Classement mondial partagé : pas encore développé.
- Synchronisation cloud : code préparatoire uniquement, non configuré et non validé de bout en bout.

## Supabase facultatif
Le schéma SQL et un exemple de configuration sont conservés. Les jeux locaux fonctionnent sans Supabase. Le fichier `config.js` n'est pas inclus. Ne publie jamais une clé secrète ou `service_role` dans le navigateur ou dans GitHub.

## Tests à effectuer avant publication
- Tester les cinq jeux et le Battle local.
- Vérifier les commandes tactiles sur téléphone.
- Vérifier records, XP, niveaux et préférences après rechargement.
- Tester le mode hors ligne après un premier chargement complet.
- Vérifier la mise à jour du service worker après chaque déploiement.

**État qualité :** les fichiers V1 et V2 sont réunis dans ce dépôt. Ils doivent encore être testés sur de vrais navigateurs et appareils avant d'être considérés comme une version de production.
