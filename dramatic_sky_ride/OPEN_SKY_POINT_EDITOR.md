# Open Sky city editor

This release includes a city-only calibration editor designed to produce the final Kanto and Johto coordinates that can be integrated into Dramatic Sky Ride.

## Recommended validation workflow

1. Enter Open Sky and press **F8**. The editor jumps directly to the first city in the current region.
2. Move the selected city marker with the arrow keys until it sits on the correct visual location.
3. Press **F9** to validate it. The editor automatically advances to the next city.
4. Repeat until the HUD shows `VALIDATED 10/10`, then press **F5** and validate the other region.
5. Once both regions are done, press **F11**. The complete validated report is copied to the system clipboard when the runtime exposes clipboard support. Paste that text directly into the project discussion.

The report is also printed between `[DSR OPEN SKY CALIBRATION BEGIN]` and `[DSR OPEN SKY CALIBRATION END]` in the runtime log as a fallback.

## Controls

- **F8**: enter / leave the city editor
- **F5**: switch Kanto / Johto
- **F6 / F7**: previous / next city and jump to its current position
- **Arrow keys**: move the selected city position
- **Shift + Arrow keys**: fine adjustment
- **Ctrl + Arrow keys**: ultra-fine adjustment
- **F9**: validate the current city and automatically advance to the next city
- **F10**: discard the current city's in-session override and return it to the bundled position
- **F11**: copy/export every validated city coordinate from both regions
- **F4**: clear every in-session validation and return to the bundled coordinates

Normal Open Sky movement is frozen while the editor is active.

## HUD

The editor HUD shows:

- selected region and city number;
- number of validated cities in that region;
- exact landmark ID;
- current X/Y;
- bundled/base X/Y;
- delta from the bundled point;
- `[VALIDATED]` or `[NOT VALIDATED]`.

## Report format

The exported lines use exactly:

`region|landmark_id|x|y`

Example:

`kanto|LANDMARK_CELADON_CITY|76.25|68.50`

Only cities explicitly validated with F9 are included. There are 10 Johto cities and 10 Kanto cities, so a complete report contains **20 coordinate lines**.

These coordinates are session-only. After the final report is submitted, they can be written permanently into the mod's bundled landmark data without adding filesystem permissions.
