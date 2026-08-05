# Dramatic Sky Ride — alpha.12

Addon indépendant pour **Gen1Recomp** et **Dramatic Shape Voxel Mod**. Il ajoute des montures volantes dans les vues voxel `FULL`, `15`, `35`, `50`, `75`, `1ST` et `3RD`.

## Changements alpha.12

- suppression complète de `AUTO FLY` et de sa dépendance à la carte des destinations ;
- le vol reste entièrement manuel, libre et continu en `1ST` et `3RD` ;
- le suivi automatique de caméra reste disponible et ne pilote jamais la monture ;
- le boost conserve son calcul unique par frame pour éviter les déplacements saccadés ;
- les dix montures logiques de première génération restent disponibles ;
- l'intégration Pokémon Stadium reste entièrement supprimée.

## Pokémon utilisables

Les Pokémon suivants peuvent utiliser `RIDE & FLY` lorsqu'ils sont dans l'équipe et ne sont pas K.O. :

- Dracaufeu — `follower_006.png` ;
- Roucarnage — `follower_018.png` ;
- Rapasdepic — `follower_022.png` ;
- Nosferalto — `follower_042.png` ;
- Ptéra — `follower_142.png` ;
- Artikodin — `follower_144.png` ;
- Électhor — `follower_145.png` ;
- Sulfura — `follower_146.png` ;
- Draco — `follower_148.png` ;
- Dracolosse — `follower_149.png`.

Dodrio, Papilusion, Dardargnan, Insécateur et les petits Pokémon capables de léviter ne sont pas inclus : apprendre `VOL` ou quitter le sol ne signifie pas forcément pouvoir porter le dresseur de manière crédible.

## Contrôles

| Action | Clavier | Manette |
|---|---|---|
| Déplacement | Flèches / touches configurées | Stick gauche / croix |
| Regarder | Souris | Stick droit |
| Monter | `Page Up` | `R2` |
| Descendre | `Page Down` | `L2` |
| Accélérer | bouton B configuré | `B` du jeu |
| Atterrir | bouton A configuré | `A` du jeu |
| Monture rapide | `F` | `SELECT + R1` |

### Suivi de caméra

Avec `CAMERA FOLLOW : ON` :

- en `3RD`, la caméra revient progressivement derrière la trajectoire réelle ;
- en `1ST`, elle accompagne doucement les changements de direction sans rotation instantanée ;
- une action sur le stick droit ou la souris donne immédiatement la priorité au joueur ;
- le suivi reprend après une courte temporisation ;
- reculer ne provoque pas de demi-tour automatique brutal.

Avec `CAMERA FOLLOW : OFF`, la caméra reste entièrement manuelle.

## Autres fonctions conservées

- vue depuis les yeux du dresseur en `1ST` ;
- dresseur masqué en première personne ;
- accès normal au menu pendant le vol ;
- altitude manuelle de 20 à 96 pixels ;
- sécurité automatique au-dessus du relief et des grands bâtiments connus ;
- marqueur vert ou rouge d'atterrissage ;
- ombre dynamique ;
- battement d'ailes sans variation de hauteur ;
- suspension des rencontres, warps au sol et lignes de vue des dresseurs ;
- protection `STORY SAFE` pour les entités runtime de quêtes ;
- restauration des compagnons après l'atterrissage ;
- avertissement `LAND FIRST` sans atterrissage forcé pour les raccourcis externes incompatibles.

## Prérequis obligatoires

Avant d’installer Sky Ride, il faut déjà disposer de :

1. **Gen1Recomp**, dans une version compatible avec l’API de mods 2 ;
2. **Dramatic Shape Voxel Mod 1.6.0 ou plus récent**, qui fournit le monde 3D, les vues `1ST`/`3RD` et le déplacement libre :
   https://github.com/DramaticShape/DramaticShapeVoxelMod
3. **un fournisseur compatible de sprites PokePC**, soit `PokePC Followers`, soit `PokePC Followers Voxel Merge`. Sky Ride lit leurs feuilles de sprites 16×96 déjà installées et ne redistribue pas les graphismes Pokémon.

`Followers EX` n’est pas obligatoire. Il est toutefois pris en charge : ses compagnons sont masqués pendant le vol puis restaurés après l’atterrissage.

La dépendance PokePC reste déclarée comme optionnelle dans le manifeste uniquement parce que plusieurs variantes utilisent des identifiants différents. **En pratique, l’une des installations PokePC compatibles est nécessaire pour afficher les montures.**

## Installation

Supprimer l'ancien dossier, puis extraire l'archive dans le dossier `mods` :

```text
mods/
├── DramaticShapeVoxelMod/
├── PokePCFollowers/
└── dramatic_sky_ride/
    ├── manifest.json
    ├── main.lua
    ├── src/
    │   └── source parts main_01.lua … main_14.lua
    ├── mod.card
    ├── README.md
    └── TESTING.md
```

Redémarrer complètement Gen1Recomp après le remplacement.

## Options conseillées

```text
SHOW RIDER       ON
MANUAL ALTITUDE  ON
ALTITUDE DISPLAY TEMPORARY
VERTICAL SPEED   NORMAL
LANDING MARKER   ON
DYNAMIC SHADOW   ON
MOUNT SHORTCUT   ON
FLIGHT BOOST     ON
CAMERA FOLLOW    ON
SOUND & RUMBLE   ON
STORY SAFE       ON
```

## Limites restantes

- les offsets visuels des nouvelles montures doivent être vérifiés en jeu ;
- la détection géométrique complète des toits n'est pas encore intégrée ;
- la posture assise dédiée du dresseur reste prévue pour plus tard ;
- cette archive a été validée par analyse et simulation, mais seul un test dans Gen1Recomp confirme le rendu final de chaque sprite.
