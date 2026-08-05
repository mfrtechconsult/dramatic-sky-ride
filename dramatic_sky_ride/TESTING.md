# Test ciblé — Dramatic Sky Ride alpha.13

Utiliser `OK`, `KO`, `PARTIEL` ou `N/T`.

## 1. Régression principale

| ID | Test | Résultat attendu | Statut |
|---|---|---|---|
| A13-01 | Démarrer le jeu | Aucun message lié à Stadium, aucune option Stadium | |
| A13-02 | Décoller avec Dracaufeu ou Roucarnage | Fonctionnement identique à alpha.9/10 | |
| A13-03 | Ouvrir le menu en vol | Menu accessible, vol conservé | |
| A13-04 | Battement d'ailes | Aucune variation verticale | |
| A13-05 | Atterrissage valide/invalide | Même comportement que précédemment | |
| A13-06 | Ouvrir le menu en croisière | Aucune entrée `AUTO FLY` | |

## 2. Contrôles libres

| ID | Test | Résultat attendu | Statut |
|---|---|---|---|
| CTL-01 | Se déplacer en `3RD` avec le stick analogique | Mouvement libre, continu et non quadrillé | |
| CTL-02 | Se déplacer en `1ST` | Mouvement libre relatif à la caméra | |
| CTL-03 | Maintenir le boost en ligne droite | Accélération fluide, sans alternance rapide/lente | |
| CTL-04 | Booster en diagonale | Trajectoire régulière, sans double pas | |
| CTL-05 | Tourner pendant le boost | Aucun saut de position | |
| CTL-06 | Relâcher le boost | Retour progressif à la vitesse normale | |

## 3. Suivi de caméra

| ID | Test | Résultat attendu | Statut |
|---|---|---|---|
| CAM-01 | Voler latéralement en `3RD` | La caméra se replace doucement derrière la trajectoire | |
| CAM-02 | Changer de direction plusieurs fois | Aucun claquement par quarts de tour | |
| CAM-03 | Bouger le stick droit | Le suivi automatique cesse immédiatement | |
| CAM-04 | Relâcher le stick droit | Le suivi reprend après une courte pause | |
| CAM-05 | Déplacer la souris | Même priorité manuelle qu'au stick droit | |
| CAM-06 | Reculer | Aucun demi-tour automatique brutal | |
| CAM-07 | Désactiver `CAMERA FOLLOW` | Caméra totalement manuelle | |
| CAM-08 | Ouvrir puis fermer le menu en `1ST` | Souris libérée puis recapturée correctement | |

## 4. Nouvelles montures

Tester le sous-menu et le décollage pour chaque Pokémon disponible :

| ID | Pokémon | Fichier attendu | Statut | Défaut visuel |
|---|---|---|---|---|
| MON-01 | Dracaufeu | `006` | | |
| MON-02 | Roucarnage | `018` | | |
| MON-03 | Rapasdepic | `022` | | |
| MON-04 | Nosferalto | `042` | | |
| MON-05 | Ptéra | `142` | | |
| MON-06 | Artikodin | `144` | | |
| MON-07 | Électhor | `145` | | |
| MON-08 | Sulfura | `146` | | |
| MON-09 | Draco | `148` | | |
| MON-10 | Dracolosse | `149` | | |

Pour chaque monture, vérifier : palette, quatre directions, position du dresseur, première personne, marqueur, ombre et atterrissage.

## Rapport

```text
ID :
Statut : KO / PARTIEL
Pokémon :
Carte et vue :
Manette ou clavier :
Étapes :
Résultat :
Résultat attendu :
Capture/vidéo :
```

## 5. Atterrissage sur l'eau et redécollage

| ID | Test | Résultat attendu | Statut |
|---|---|---|---|
| SURF-01 | Survoler l'eau sans Pokémon connaissant `SURF` | Marqueur rouge et message `SURF REQUIRED` | |
| SURF-02 | Ajouter un Pokémon connaissant `SURF`, puis survoler la même case | Marqueur vert | |
| SURF-03 | Appuyer sur A au-dessus de l'eau | Descente normale puis état de surf actif sur la case visée | |
| SURF-04 | Se déplacer après l'atterrissage | Déplacement aquatique natif et musique de surf | |
| SURF-05 | Appuyer sur `F` en surfant | Décollage immédiat avec la dernière monture valide | |
| SURF-06 | Utiliser `SELECT + R1` en surfant | Même résultat que `F` | |
| SURF-07 | Atterrir sur la terre après un décollage depuis l'eau | État de surf désactivé et musique de carte restaurée | |
| SURF-08 | Atterrir sur l'eau avec Pikachu connaissant `SURF` | Sprite Surfing Pikachu utilisé lorsque le moteur le permet | |
| SURF-09 | Ouvrir le menu pendant le vol et retirer/remplacer `SURF` avant de toucher l'eau | Atterrissage annulé proprement avec `SURF REQUIRED` | |
