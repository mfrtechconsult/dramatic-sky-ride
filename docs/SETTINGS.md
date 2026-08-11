# Settings

Dramatic Sky Ride has a large configuration surface because Flight, Ground Ride, Surf, progression, rendering and integrations can all be tuned independently. The menu therefore provides two presentation modes.

## Settings View

### SIMPLE

`SETTINGS VIEW = SIMPLE` shows the main controls most players are likely to use:

- Show Rider
- Flight Speed
- Ground Speed
- Manual Altitude
- Visible Surf Mounts
- Realistic Mount Sizes
- Mount Hints

Additional rows appear only when relevant:

- Air Encounters — when Wild Skies is installed;
- Flying Music — when compatible tracks are available;
- Mount Renderer — when Stadium rendering is relevant.

Simple mode does **not** change the value of any hidden setting.

### ADVANCED

`SETTINGS VIEW = ADVANCED` exposes the complete DSR configuration surface.

The current implementation keeps Advanced as the conservative default so an existing installation never appears to lose settings after upgrading. Players who prefer the cleaner interface can switch to Simple at any time.

## Size Overrides

Advanced mode contains:

`SIZE OVERRIDES = HIDDEN / EDIT`

- `HIDDEN` keeps all per-species size rows out of the menu;
- `EDIT` reveals the individual `SIZE <POKEMON>` rows.

Changing this display switch never resets a saved mount size.

## General

| Setting | Purpose |
|---|---|
| Show Rider | Show or hide the trainer while mounted. |
| Mount Cries | Play mount cries where supported. |
| Mount Hints | Show contextual mount hints. |
| Mounts Menu | Enable the DSR mount-selection menu. |
| Show Followers | Allow followers to remain visible while mounted where supported. |
| Sound & Rumble | Flight feedback through sound/controller rumble where available. |

## Flight

| Setting | Purpose |
|---|---|
| Flight Speed | Scale horizontal Flight movement from 50% to 200%. |
| Manual Altitude | Enable direct altitude control. |
| Vertical Speed | Choose the rate of manual altitude changes. |
| Altitude Display | Control when the altitude indicator is visible. |
| Flight Boost | Enable the Flight boost behavior. |
| Camera Follow | Allow camera-facing/flight presentation behavior used by DSR. |
| Camera Altitude | Enable altitude behavior linked to supported camera presentation. |
| Landing Marker | Show the landing marker where applicable. |
| Dynamic Shadow | Enable DSR's dynamic mount shadow behavior. |
| Air Encounters | Allow supported Wild Skies aerial interceptions. |
| Mount Shortcut | Enable the normal DSR mount shortcut. |

## Ground Ride

| Setting | Purpose |
|---|---|
| Ground Speed | Scale Ground Ride movement from 50% to 200%. |
| Ground Gallop | Enable the gallop system. |
| Gallop HUD | Show the gallop/stamina HUD. |
| Ground Dust | Show ground movement dust effects. |
| Two-Way Ledges | Allow the supported reverse-ledge behavior while mounted. |
| Remount After Battle | Restore the Ground Ride state after supported battles. |

## Surf

| Setting | Purpose |
|---|---|
| Visible Surf Mounts | Show the selected supported Pokemon during Surf. |

## Progression and safety

| Setting | Purpose |
|---|---|
| Require Fly | Require the normal FLY capability before using Flight. |
| Badge Checks | Respect badge progression checks. |
| Story Gates | Respect DSR's story-related Flight restrictions. |
| Discovery Gates | Prevent first-time airborne entry into canonical vanilla areas that have not yet been reached normally. |
| Quest Collisions | Preserve quest/story-sensitive collision safeguards. |

Unknown or custom maps are intentionally treated more permissively by the discovery system so third-party content is not blocked by a vanilla-only map list.

## Visual and integration

| Setting | Purpose |
|---|---|
| Mount Renderer | Choose the standard 2D presentation or Stadium 3D when available. |
| Realistic Mount Sizes | Use Pokédex-proportional sizing. |
| Flying Music | Choose an available compatible flight music source or None. |
| Size Overrides | Show or hide individual per-species size rows. |

## Per-species mount sizes

DSR supports individual size overrides for the complete current mount roster. These controls are intentionally hidden until `SIZE OVERRIDES = EDIT` to keep the normal Advanced menu manageable.

The persistent option keys remain unchanged from earlier versions. The settings UX layer only changes visibility, order and selected user-facing labels.
