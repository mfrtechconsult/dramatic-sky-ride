# Stadium 2 Mount Motion — Alpha 8

This document applies only to the `experiment/stadium2-3d` branch.

## Design rule

Pokemon Stadium 2 does not provide a shared overworld `walk`, `run`, `fly` or `swim` animation contract. Its packed context slots are battle-oriented (`idle`, attacks, reactions, entrance, flinch and alternate idle states). Dramatic Sky Ride therefore does **not** invent generic bone mappings or reuse attack animations as fake locomotion.

Alpha 8 keeps each Pokemon's genuine Stadium skeletal animation and adapts the whole model to the DSR mount state:

- skeletal playback cadence follows real mount movement;
- Flight adds restrained forward pitch, climb/dive pitch and turn banking;
- Ground Ride adds morphology-specific body cadence, small forward lean and restrained turn response;
- Visible Surf adds low-frequency buoyancy, small pitch and water-turn roll;
- DSR still owns movement, collisions, altitude, progression, cameras and rider state;
- the voxel provider still owns depth, terrain, reflections and the final draw path;
- the model and its shadow use the same motion transform.

The profiles are deliberately conservative. Heavy bipeds are not made to bounce like quadrupeds, Dragonair is not treated like a bird, and Snorlax/Tyranitar receive only minimal motion. This layer never guesses individual Stadium bone indices.

## Complete role coverage

The alpha 8 table contains **41 mount-role entries**: 16 Flight, 17 Ground Ride and 8 Visible Surf. Lugia is intentionally present in both Flight and Surf. Suicune remains a Ground Ride lifecycle mount but switches to a calmer water presentation while its amphibious water state is active.

### Flight — 16

- Charizard — winged dragon
- Pidgeot — bird
- Fearow — bird
- Golbat — bat
- Aerodactyl — pterosaur
- Articuno — large bird
- Zapdos — large bird
- Moltres — large bird
- Dragonair — serpentine flyer
- Dragonite — winged dragon
- Noctowl — bird
- Crobat — bat
- Xatu — levitating bird
- Skarmory — armored bird
- Lugia — large winged flyer
- Ho-Oh — large bird

### Ground Ride — 17

- Arcanine — fast quadruped
- Rapidash — equine
- Dodrio — runner bird
- Rhyhorn — heavy quadruped
- Rhydon — heavy biped
- Kangaskhan — large biped
- Tauros — bovine
- Snorlax — very heavy biped
- Meganium — heavy quadruped
- Girafarig — equine-like quadruped
- Ursaring — heavy biped
- Donphan — heavy quadruped
- Stantler — deer
- Raikou — fast quadruped
- Entei — large quadruped
- Suicune — fast quadruped / amphibious water presentation
- Tyranitar — very heavy biped

### Visible Surf — 8

- Blastoise — bulky swimmer
- Tentacruel — tentacled swimmer
- Gyarados — serpentine swimmer
- Lapras — large swimmer
- Feraligatr — bulky swimmer
- Mantine — ray
- Kingdra — serpentine swimmer
- Lugia — large swimmer

## Runtime behavior

Motion is measured from the player's actual world-space movement instead of assuming a specific input implementation. This keeps the presentation compatible with normal tile movement and the supported free-camera movement paths.

Each active Stadium runtime tracks:

- smoothed horizontal speed;
- flight vertical speed;
- recent left/right turn impulse;
- DSR Flight boost;
- Ground Ride speed/gallop blend;
- a role-specific motion phase;
- the resulting animation-rate multiplier, bob, pitch and roll.

The public diagnostic API is:

`stadium3DMountMotion.coverage()` — complete curated roster and family mapping.

`stadium3DMountMotion.profile(role, species, dex)` — resolved profile.

`stadium3DMountMotion.stats(dex)` — current measured speed/intensity/rate/bob/pitch/roll for a live mount.

## Validation priorities

Alpha 8 should be visually checked with both Dramaless and Battle Art using the already-generated Crystal 251 Stadium 2 cache.

Recommended representative tests:

- Flight: Charizard, Pidgeot, Aerodactyl, Dragonair, Crobat, Lugia;
- Ground: Rapidash, Dodrio, Snorlax, Raikou, Suicune, Tyranitar;
- Surf: Lapras, Gyarados, Mantine, Kingdra, Lugia.

For Flight, check stationary idle, normal movement, boost, climb, dive and 90-degree turns. For Ground, compare stationary and moving presentation and ensure heavy species are not over-animated. For Surf, check idle buoyancy, forward movement and turns.

## Intentional limitation

Ground Ride is the least aggressive part of this feature. Stadium 2 has no trustworthy shared locomotion clip, and selecting a battle reaction/attack just because it moves many bones would often look worse than a restrained authentic idle. A future per-species ground gait layer should only be added when a specific source clip has been visually verified as a credible locomotion loop for that species.
