# The gas station: building the scene layer by layer

A night gas station in fog and rain: a canopy with six fluorescent fixtures over two fuel pumps, a small kiosk with warm windows, a wet concrete forecourt, haze and light shafts. This tutorial builds it in the order the layers of a look depend on each other: first the objects and their materials, then the camera, the night sky, the lights, the reflections, the fog, the rain and the post-processing. Every layer is saved before the next one starts, so each step can be compared with the one before.

Everything is real-time: nothing is baked. Every light, reflection and fog effect updates as soon as a value changes.

**The Hierarchy by layer.** In the finished scene, the Hierarchy has one parent per layer, numbered like the sections of this tutorial: `1-4 · Objects`, `6 · Wet Ground`, `7 · Camera`, `9 · Lights`, `10 · Fog`, `11 · Reflections`, `12 · Rain`, and `10-13 · Volume (fog, reflections, post)`. Switch a parent off (the checkbox at the top of the Inspector) to see what its layer adds to the frame. Build your own scene with the same parents.

The finished scene is `Gas-Station.unity`. Open it first, look at it from the camera, then build your own version in a new scene next to it. The scene's assets (materials, textures, the pump prefab, the scripts and shaders) are in the same folder, and every step below uses them.

## 0 · Before you start: the project

The scene needs four renderer features and a few settings in the URP Asset. They are project settings, so they are set once for the whole project.

**The Renderer** (`Settings/PC_Renderer`), *Add Renderer Feature*:
1. **Screen Space Ambient Occlusion** — the soft dark where objects meet.
2. **Decal** — used by other scenes; it does no harm here.
3. **Screen Space Reflection** — sharp reflections of what is on screen.
4. **Volumetric Fog** — from the *URP Volumetric Fog* package by Cristian Qiu (included in the project). It makes fog that is lit by real lights and cut by their shadows.

**The rendering path.** In the Renderer, the *Rendering Path* is **Forward+**. In Forward, each object is lit by a limited number of additional lights (*Per Object Limit*, at most 8). Forward+ has no limit per object, and this scene uses 26 lights.

**The URP Asset** (`Settings/PC_RPAsset`): **HDR** on (bright values above 1 are kept, so bloom can find them), **Depth Texture** and **Opaque Texture** on (the fog and the reflections read them), **Additional Lights: Per Pixel** with **Cast Shadows** on.

## 1 · The ground and the layout

All the geometry is made with ProBuilder (*Tools › ProBuilder › ProBuilder Window*). Sizes are in metres; one Unity unit is one metre.

1. **The forecourt.** A ProBuilder cube 60 × 0.1 × 60 m, its top at y = 0, named `Ground` under an empty parent `Forecourt`. Its UVs are set to world space in metres (*UV Editor › Auto › World Space*), so a texture's tiling is the same on every face and size.
2. **The far ground.** A large flat plane (400 m) just below the forecourt (y = −0.08), named `Far Ground`. It fills the horizon behind the fog.
3. **The station's centre** is the world origin. The station (island, canopy, rain) is turned **−25°** around Y, so its left end comes toward the camera and the canopy reads in depth, not flat on.

**Empty parents.** Make an empty parent `1-4 · Objects` for all the geometry, and inside it one parent per group, so the Hierarchy stays readable: `Forecourt`, `Island`, `Canopy`, `Kiosk`, `Price Sign`, `Backdrop`.

## 2 · The island and the pumps

1. **The curb.** A cube 7.4 × 0.18 × 1.7 m (`Curb`), and on top of it a thin lip 7.5 × 0.03 × 1.8 m (`Curb Lip`). The lip sticks out slightly: that small edge catches a highlight and makes the curb read as a solid block.
2. **The pump** is a prefab (`Prefabs/Fuel-Pump.prefab`, 1.0 × 2.0 × 0.56 m). It is built once and placed twice: a change to the prefab changes both pumps. Look inside it in Prefab Mode: a plinth, two posts, a lower panel, a meter housing, a top cap, and on each face a screen, a price display, a keypad and a nozzle in its holster. The hose is a separate mesh (`Meshes/Pump-Hose.asset`).
3. **Place the pumps** on the island at local x = −2.0 and x = +2.0, standing on the curb.
4. **The waste bin.** A small box 0.42 × 0.62 × 0.34 m with a lid, at the centre of the island.

## 3 · The canopy

1. **The slab.** A box 9.4 × 7.6 m seen from below. Its underside (the soffit) is at 4.05 m and its top at 4.45 m. Around it, a fascia 12 cm thick that hangs down to 3.90 m.
2. **The columns.** Two columns 28 cm square at local x = −1.05 and +1.05, inside the pumps, from the curb to the soffit.
3. **The ribs.** Five thin ribs (6 × 5 cm) across the soffit at x = 0, ±1.57 and ±3.13. They divide the soffit into six equal panels and catch light along their edges.
4. **The fixtures.** Six housings 1.30 × 0.06 × 0.24 m, each with two tubes (radius 2.2 cm, length 1.2 m) under it: four along the long sides at (±2.35, ±3.1), two on the short sides at (±3.92, 0), turned 90°. Name them `Fixture 1` to `Fixture 6` under `Canopy/Light Fixtures`. Their lights come in § 9.

**Several materials on one mesh.** The slab has two materials, one on its top and one on its underside. A mesh with several materials can be skipped by the **GPU Resident Drawer** (the URP Asset's fast drawing path) when it is built with ProBuilder: add a **Disallow GPU Driven Rendering** component to such meshes if they disappear in the Game view.

## 4 · The kiosk, the sign and the backdrop

1. **The kiosk** stands at (9.2, 0, 4.32), turned **65°**, so its front faces the station. A box 6.4 × 4.6 × 3 m, a roof slab 7.0 × 0.28 × 5.6 m that overhangs the front, a front step 6.8 × 0.14 × 1.4 m.
2. **Its front**, from left to right: a solid door, a window with one centre mullion (from 0.9 to 2.3 m high), and a night-pay counter window with a small hatch and a steel tray. Cut the openings with ProBuilder (select the faces, *Extrude* inward or *Subdivide* and delete). Thin dark frames go around every opening.
3. **The interior** is only seen through the glass: a counter, a shelf of goods, a fridge with a glowing front, a ceiling panel. Simple boxes are enough.
4. **The price sign** at (−8.8, 0, −7.3): a pole (radius 0.12 m, 5 m tall), a cabinet 1.9 × 2.6 × 0.3 m at 6.1 m height, and a flat face in front of it for the prices.
5. **The backdrop.** Wooden poles every 22 m along a line 26 m behind the station, 10 m tall, with three wires between them. The wires are **Line Renderers** (width 3.5 cm), each with a few points that sag in the middle. Two street lamps on 8 m posts stand at x = −30 and x = 24. In the fog, only their glow will be seen.

**Save the scene.** This is the first checkpoint: the geometry, in grey.

## 5 · Materials and textures

Every surface uses **Universal Render Pipeline/Lit**, except the wet ground (§ 6) and the rain (§ 12). The textures are two sets from Poly Haven (CC0): `concrete_floor_worn_001` and `green_metal_rust`. Each set has an albedo map, a normal map, and a map that holds metallic and smoothness (the `…-MetalSmooth.png` files in `Textures/URP/`, one per material, with the ambient occlusion in green).

1. **The concrete materials.** `GS-Concrete-Curb` (curb, kiosk floor and step), `GS-Concrete-Wall` (kiosk walls), `GS-Concrete-Roof` (both roof tops). Base Map: the concrete albedo; Normal Map: the concrete normal; Metallic Map: the material's own MetalSmooth map. Tiling around 0.5 to 0.8, so one tile covers 1.2 to 2 m.
2. **The metal materials.** `GS-Metal-Canopy` (fascia, soffit, ribs, fixture housings, sign pole), `GS-Metal-Column`, `GS-Metal-Pump`, `GS-Metal-Green` (bin, kiosk door). They use the rusted-metal maps. The canopy and column metals use a neutral grey copy of the albedo (`green_metal_rust_albedo_neutral.jpg`), tinted by the Base Color, so one texture gives several metals.
3. **The plain materials**, with no maps: `GS-Steel` (metallic 1, smoothness 0.55: spouts, nozzles, keypads), `GS-Rubber` (almost black, smoothness 0.35: hoses and grips), `GS-Plastic-Sign` (pump sign panels), `GS-Asphalt-Far` (very dark, smoothness 0.6), and the two silhouette materials for the poles and wires.
4. **The emissive materials.** These surfaces give off light of their own. Tick **Emission** and set the HDR colour. In the colour picker, *Intensity* multiplies the colour by 2 to the power of the value: 1 doubles it, 3 multiplies it by eight.

| Material | On | Emission colour (0–255) | Intensity | Emission Map |
|---|---|---|---|---|
| `GS-Tube-Glass` | the fluorescent tubes | 170, 230, 255 | 2.9 | — |
| `GS-Lamp-Glass-Warm` | wall lamp glass, interior ceiling panel | 255, 217, 162 | 2.4 | — |
| `GS-Sodium-Glass` | street lamp heads | 255, 195, 127 | 2.0 | — |
| `GS-Glass-Window` | both kiosk windows | 255, 188, 120 | 0.5 | `Window-Glow.png` (brighter at the top) |
| `GS-Fridge-Glow` | fridge front | 224, 249, 255 | 0.4 | — |
| `GS-Price-Sign` | sign face | 255, 255, 255 | −0.6 | `Price-Sign.png` (the prices) |
| `GS-Screen` | pump screens and price displays | 191, 255, 236 | −1.1 | — |

**Transparent glass.** The window glass is also **Transparent** (*Surface Type*), with an alpha of 0.75 in its Base Color, and it casts no shadows (*Mesh Renderer › Lighting › Cast Shadows: Off*), so the light from inside passes through.

**Emission and light.** An emissive surface is only bright itself: it does not light anything around it. The light that falls on the canopy and the ground comes from real Light components, placed beside the emissive surfaces in § 9.

**Save the scene.**

## 6 · The wet ground

The forecourt uses its own shader, `Gas-Station/Lit Wet Ground`: a copy of URP's Lit shader with three additions. The material is `GS-Concrete-Ground`.

1. **The base.** The concrete maps, a dark grey Base Color (71, 71, 71), tiling 0.4 (one tile every 2.5 m), and a strong normal (Normal Map scale 2.4), so the wet surface breaks highlights into streaks.
2. **The wet map.** One texture laid over the whole forecourt (`Textures/URP/Wet-Map.png`) tells the shader where each kind of wetness is: **red** for puddles (darker and very smooth: smoothness 0.92), **green** for oil stains (almost black and glossy), **blue** for where rain falls (outside the canopy). The puddles sit where they will mirror the lights toward the camera: in front of the island and along the lines below the fixtures.
3. **The ripples.** Rings on the water where drops land. The shader reads a normal map (*Ripple Normal*, tile 1.2 m, strength 0.35) only where the wet map is blue. An empty GameObject `Ripples` carries the **Ripple Flipbook** script: it steps the material's `_RippleMap` through the 16 frames in `Textures/Ripples/` at 18 frames per second, so the rings appear and fade.

**The Water layer.** Put `Ground` and `Far Ground` on the built-in **Water** layer (*Inspector › Layer*). The planar reflection in § 11 uses this layer.

## 7 · The camera

The frame is decided before the lights, because lights are placed for what the camera sees.

1. **The frame.** In the Game view, set the resolution to **1920 × 1080** (16:9).
2. **Main Camera:** position (−0.3, 1.3, −26.5), rotation (−3.7, 0.6, 0): eye height, looking very slightly up. **Field of View 40** (vertical). Clipping Planes: Near 0.05, Far 300.
3. **Rendering.** In the camera's *Rendering* section: **Post Processing** on, **Anti-aliasing: Temporal Anti-aliasing (TAA)**, **Dithering** on (it hides banding in the dark gradients of the fog).
4. **The reference overlay (optional).** The `Reference Overlay` canvas shows the reference image, semi-transparent, over the Game view, to match the frame. Switch it off when the frame is right.

## 8 · Night: the sky and the ambient

Open the Lighting window: *Window › Rendering › Lighting › Environment*.

1. **Skybox Material:** `GS-Procedural-Sky` (shader `Gas-Station/Procedural Night Sky`). It starts from three colours blended by height (top, middle, bottom) in a very dark teal, and adds what the shader computes itself: clouds drifting slowly, lit from below by a warm glow along the horizon (the town), stars that the clouds cover, and a moon with a soft glow. All its colours are typed as small linear numbers, because the sky must be about a hundred times darker than the lights. Try *Cover*, *Drift* and the moon's *Direction*; in the fog, the moon and the horizon glow read most. The simpler `GS-Gradient-Sky` (the three colours only) is in the same folder.
2. **Environment Lighting:** *Source: Gradient*, with the same three colours as the sky (Sky, Equator, Ground). This is the light every surface receives from all around. At night it is low and coloured, never black.
3. **Environment Reflections:** *Source: Custom*, no cubemap, so the shiny surfaces reflect nothing from the sky. The wet ground will only mirror the station and its haze.
4. **Sun Source:** leave it empty for now; § 10 sets it.
5. **Lighting Settings.** The scene's Lighting Settings asset has *Baked Global Illumination* and *Realtime Global Illumination* both off. Nothing is baked.

**Save the scene.**

## 9 · The lights

URP's rectangle (area) lights work only with baked lighting, so the fluorescent fixtures are made from **spot** and **point** lights. Each fixture gets three lights placed at the fixture: an Area Light and a Tube Light under `9 · Lights › Canopy › Fixture n Lights`, and a Fog Spot, which belongs to the fog layer (`10 · Fog › Fog Spots`, § 10). The kiosk's, the sign's and the street lamps' lights have their own parents under `9 · Lights`. Copy the first fixture's lights to the other five once they look right.

| Light | Type | Intensity | Range | Spot angle (outer / inner) | Colour (0–255) | Shadows | Notes |
|---|---|---|---|---|---|---|---|
| **Area Light** (×6) | Spot, pointing down, 12 cm under the soffit | 5.3 | 30 | 170 / 169 | 102, 204, 255 | Soft | Cookie: `Lambert-Spot-170` |
| **Tube Light** (×6) | Point, at the tube | 0.9 | 25 | — | 102, 204, 255 | None | the soft light all around the fixture, on the soffit |
| **Fog Spot** (×6) | Spot, pointing down | 3.5 | 8 | 170 / 90 | 92, 199, 255 | Soft | lights only the fog (§ 10) |
| **Ceiling Light** | Spot, down, inside the kiosk | 6.4 | 25 | 170 / 169 | 255, 140, 56 | Soft | Cookie: `Lambert-Spot-170` |
| **Window Beam** (×2) | Spot, from inside, out through each window, slightly down | 104 | 13 | 30 / 18 | 255, 140, 56 | Soft | the warm shafts out of the windows |
| **Lamp Light** | Spot, from the wall lamp, down and out | 1.1 | 18 | 120 / 50 | 255, 179, 92 | Soft | Cookie: `Lambert-Spot-170` |
| **Sign Glow** | Spot, toward the camera, in front of the sign | 0.42 | 12 | 120 | 217, 230, 255 | None | the sign's halo |
| **Sodium Light** (×2) | Spot, down, in each street lamp | 3.3 | 25 | 110 | 255, 140, 51 | None | far away; only the glow will read |

**Why a cookie on the wide spots.** A Spot light's brightness falls off quickly toward the edge of its cone. A flat panel of light (a fluorescent fixture) instead sends a lot of light sideways. The cookie `Textures/URP/Lambert-Spot-170.png` (*Texture Type: Cookie*) makes a 170° spot fade gradually from its centre to its edge, like a panel. With the inner angle almost equal to the outer one (169°), the cookie alone decides the falloff.

**Why the window beams are so bright.** Their cone is narrow (30°), so the same amount of light is concentrated into a small area. The kiosk's walls shadow them, so once the fog is on each window sends out its own shaft.

**Save the scene.** The station is now lit, but the air is still clear.

## 10 · The fog and the light shafts

The fog comes from the Volumetric Fog renderer feature (§ 0). It is controlled from a Volume, and each light must be added to it one by one.

1. **The Volume.** *GameObject › Volume › Global Volume*, named `Gas-Station Volume (global)`, with the profile `Gas-Station-Volume`. Add the override **Volumetric Fog**: *Enabled* on; *Distance* 100; *Base Height* 0, *Maximum Height* 16 (the fog thins out with height); *Density* 1; *Attenuation Distance* 15 (how far one sees through it); *Anisotropy* 0; *Scattering* 1; *Main Light* and *Additional Lights* contributions on; *Max Steps* 128; *Blur Iterations* 2.
2. **Render Pass Event: Before Rendering Transparents.** The fog is then drawn before the reflections take their picture of the frame, so the wet ground mirrors the haze too (§ 11).
3. **Add each light to the fog.** A light shows in the fog only with a **Volumetric Additional Light** component on it. Its *Scattering* is how much of its light the fog catches:

| Light | Scattering |
|---|---|
| Fog Spot | 4.34 |
| Ceiling Light | 1.24 |
| Sign Glow | 0.6 |
| Lamp Light, Sodium Light | 0.5 |
| Window Beam | 0.48 |
| Area Light | 0.1 |
| Tube Light | 0.06 |

4. **The fog-only lights.** The Fog Spots carry most of the haze under the canopy, but they should not light the surfaces a second time. The fog feature ignores **Rendering Layers**, while surfaces respect them. So the Fog Spots are set to a Rendering Layer that no object uses (*Light › Rendering › Rendering Layers*, a spare layer, for example layer 15), and their shadows keep the default layers, so the canopy, the columns and the pumps still cut their light into shafts. Their short Range (8 m) ends the bright haze about where the canopy ends.
5. **The distance fog.** Unity's own fog, in the Lighting window (*Environment › Other Settings › Fog*): on, *Mode: Exponential Squared*, *Density* 0.015, colour the sky's middle (very dark teal). It fades every surface with its distance from the camera, independently of the volumetric fog: the backdrop and the far ground fade first. Without the Volumetric Fog package, it is the only fog in the scene.
6. **The fog's sky light.** The fog is lit only by lights, never by the sky. A **Directional Light** pointing straight down, named `Fog Ambient (fog only)`, on the same spare Rendering Layer, gives the whole fog a faint teal glow: Intensity 0.012, colour 88, 194, 255, no shadows. In the Lighting window, set it as the **Sun Source**. The fog uses the main light for its general glow.

**Save the scene.** Compare it with the previous save: the halos around the fixtures, the shafts between the columns and the warm beams out of the kiosk come from this step.

## 11 · Reflections on the wet ground

A smooth surface shows what is around it. Here three things are reflected: the station, the lights and the haze. The scene uses two kinds of reflection together.

1. **Screen Space Reflections (SSR)** for every surface except the ground. In the Volume, add **Screen Space Reflection**: *Mode* switched on (not *Disabled*), *Minimum Smoothness* 0.25 (rougher surfaces reflect nothing), *Smoothness Fade Start* 0.35, *Max Ray Length* 60, *Max Ray Steps* 128, *Roughness Scale* −3 (sharp reflections, stretched into streaks). SSR can only reflect what is on screen: an object outside the frame, or hidden behind another, is missing from the reflection.
2. **A planar reflection** for the ground. A second camera, mirrored below the ground, renders the scene upside down into a texture, and the wet-ground shader reads it. This reflects the haze, which SSR cannot capture well on a rough, bumpy surface.
   - An empty GameObject `Planar Reflection` with the **Planar Reflection** script: *Source* the Main Camera, *Plane Height* 0, *Resolution Scale* 0.5. The script creates its own child `Reflection Camera`.
   - Its *Culling Mask* leaves out the **Water** layer, so the ground does not block the view from below. Its *Volume Mask* is Water too: it uses only a second Volume, `Planar Reflection Volume (fog only)`, placed on the Water layer, whose profile has the fog and nothing else (no colour grading, so the grade is not applied twice).
   - *Reflect Sky* off: where the mirrored camera sees the sky, it sees black.
   - In the ground material: *Planar Reflection Strength* 3.5, *Distortion by the normal* 0.03, *Vertical stretch* 0.35 (the long vertical streaks of light on wet asphalt). *Smoothness seen by SSR* 0, so SSR does not reflect on the ground a second time.

**Save the scene.**

## 12 · The rain

The rain is four **Particle Systems** (*GameObject › Effects › Particle System*) under an empty `Rain` at y = 12, turned −25° like the station. They are four boxes around the canopy, so no drop starts above it and the space under the canopy stays dry.

| Emitter | Centre (local) | Box size (m) | Rate over Time |
|---|---|---|---|
| Rain Front | (0, 0, −16.95) | 36 × 26.1 | 11 275 |
| Rain Back | (0, 0, 10.95) | 36 × 14.1 | 6091 |
| Rain Left | (−11.4, 0, 0) | 13.2 × 7.8 | 1236 |
| Rain Right | (11.4, 0, 0) | 13.2 × 7.8 | 1236 |

1. **Main module:** Start Lifetime 1.33 s, Start Size 0.02 (2 cm). The drops fall from 12 m at 9 m/s, so they die exactly at the ground.
2. **Shape:** Box, with the size from the table, flat.
3. **Velocity over Lifetime:** (0.5, −9, 0.15): straight down with a slight slant.
4. **Renderer:** *Render Mode: Stretched Billboard*, *Velocity Scale* 0.06, so each drop is drawn as a streak in the direction it falls. Material `GS-Rain-Streak`: *Universal Render Pipeline/Particles/Lit*, Transparent, *Blend Mode: Additive*, alpha 0.4. Lit particles take the colour of the lights they pass through: the drops shine cyan under the canopy lights and warm near the kiosk.
5. **The splashes.** A child Particle System `Splash`, used as a **Sub Emitter** of the rain on *Death*: 1 to 3 splashes per drop, lifetime 0.12 to 0.25 s, size 2 to 4 cm, *Shape: Hemisphere*, *Gravity Modifier* 1.5. Material `GS-Rain-Splash`.

**In the Editor.** The rain moves only while one of its Particle Systems is selected, or in Play mode.

## 13 · Post-processing

Post-processing works on the finished image, after everything above. Add these overrides to the same global Volume.

1. **Tonemapping:** *Neutral*. It brings the bright values (the tubes, the beams) back into the range the screen can show without changing the colours much.
2. **Bloom:** Threshold 0, Intensity 0.9, Scatter 0.9, *High Quality Filtering* on. Every bright surface glows, the tubes and the windows the most.
3. **Shadows Midtones Highlights:** Shadows (0.8, 1, 1.03), Midtones (0.88, 1, 1.02). A little red is taken out of the dark and middle tones, which keeps the night teal.
4. **Split Toning:** Shadows (0.38, 0.50, 0.56), Highlights (0.60, 0.53, 0.45), Balance −15: cool shadows, warm highlights.
5. **Screen Space Lens Flare:** Intensity 0.35 (first flare 0.6, secondary 0.3, warped 0.3; streaks 0.5, length 0.4, threshold 0.4). The bright tubes leave the streaks and ghosts of a camera lens.
6. **Chromatic Aberration:** 0.08. A faint colour fringe toward the edges of the frame, as in a real lens.
7. **Vignette:** Intensity 0.3, Smoothness 0.5.
8. **Film Grain:** *Type: Medium 3*, Intensity 0.2.

**Save the scene.** Compare your saves from the first to the last: each one shows what its layer adds.

## 14 · The flickering tube (optional)

`Fixture 1`, the one nearest the camera, flickers like a failing fluorescent tube. The **Tube Flicker** script on it drives the three lights of the fixture and its own tube material (`GS-Tube-Glass-Flicker`, a copy of `GS-Tube-Glass`) together: mostly on, with a burst of short drop-outs every few seconds. *Emission Property* is `_EmissionColor`. It runs in the Editor too, so the scene shows as changed while it is open.

## References and additional materials

- Unity Manual (Unity 6): *Universal Render Pipeline › Lighting*, *Light component*, *Light cookies*, *Rendering Layers*, *Screen Space Reflection*, *Volumes*, *Particle System modules*.
- *URP Volumetric Fog* by Cristian Qiu: github.com/CristianQiu/Unity-URP-Volumetric-Light.
- Poly Haven (CC0): *Concrete Floor Worn 001*, *Green Metal Rust*.
