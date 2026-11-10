# Third Party Notices

Every asset or piece of code in this package that is not my own: its author, source and licence.

| Item | Author | Source | Licence |
|---|---|---|---|
| `Shaders/Surfaces/Simple-Toon/` (`STOutline.shader`, `STCore.hlsl`, `STFunctions.hlsl`) and `Materials/STOutline.mat` | Petar Mavrodiev (his word, 10-27) [?] | [?] | [?] No licence or author note is in the files. The names ("SToon", the `ST` prefix) look like a published toon shader; to confirm before release. |
| Showcase `Samples~/Texture-Tools-Showcase/Raw-Set/` and `Example-Output/Stone-Paving/` (renamed copies of PavingStones038, 1K; the packed map made by the tool) | ambientCG | https://ambientcg.com/view?id=PavingStones038 | CC0 1.0 |

My own, for the record: every other shader in `Shaders/` (Common, Surfaces, Light-And-Space, Weathering, Skies, Debug) and the materials in `Materials/`. `Shaders/Skies/TriColorSkyboxGradient.shader` came from the Dancerex project (its menu name was `Dancerex/TriColorSkyboxGradient`). `Materials/M_Curtain` is not here: it uses an ambientCG texture, so it stays in the asset library (`Materials/Shaders/M_Curtain.mat`).

## Weathering (10-27)

| Item | Author | Source | Licence |
|---|---|---|---|
| `Shaders/Weathering/Textures/Ripples/Ripple-00…15.png` (16 normal-map frames) | Petar Mavrodiev (from his Gas-Station, URP-Tests) [?: how they were made, by script or a tool] | Workshop / URP-Tests | my own [?] |
| `Shaders/Weathering/Textures/T_Decal_Soft-Square_Mask.png`, `Materials/M_Decal_Rain-Ripples.mat` | Petar Mavrodiev (made by script) | Workshop | my own |
| `Runtime/RippleFlipbook.cs` | Petar Mavrodiev (from his Gas-Station, `Iteration-1-HDRP-Port/Scripts/RippleFlipbook.cs`, rewritten for the toolbox) | Workshop | my own |

## Shaders (10-27)

| Item | Author | Source | Licence |
|---|---|---|---|
| `Shaders/Surfaces/Triplanar.shader`, `Shaders/Surfaces/Screen.shader`, `Shaders/Light-And-Space/Caustics.shader`, `Shaders/Light-And-Space/Glow-Volume.shader` | Petar Mavrodiev (drafted with an AI assistant, 10-27, from the toolbox's own `Common/Library-*.hlsl`) | Workshop | my own |
| `Shaders/Light-And-Space/Meshes/Beam-Cone.asset`, `Shaders/Light-And-Space/Textures/T_Beam-Gradient.png` (moved from The-Flooded-Arcade, GUIDs kept) | Petar Mavrodiev (made in the Workshop) | Workshop | my own |
| `Materials/M_Fake-Beam.mat`, `M_Glow_Sodium.mat`, `M_Glow_White.mat`, `M_Toon.mat`, `M_Flat.mat` (`M_Toon` and `M_Flat` are copies of `STOutline.mat`, so they follow its row above) | Petar Mavrodiev | Workshop | my own |
| Showcases `Surfaces-Showcase` and `Light-And-Space-Showcase`: `T_Showcase_Checker.png` (drawn by script) and `T_Showcase_Screen-Content.png` (drawn with TextMesh Pro's LiberationSans SDF) | Petar Mavrodiev; the LiberationSans typeface by Red Hat / Ascender | Workshop; TextMesh Pro | my own; the font under the SIL Open Font License 1.1 [?: check the licence line TMP ships with it] |

## Reflections (10-27)

| Item | Author | Source | Licence |
|---|---|---|---|
| `Runtime/PlanarReflection.cs` (moved from `Assets/_WIP/Gas-Station/Scripts/`, GUID kept; extended: several per scene, the reflection renders only while its source camera does) | Petar Mavrodiev (from his Gas-Station, URP-Tests) | Workshop / URP-Tests | my own |
| `Shaders/Common/Planar-Reflection.hlsl`, `Shaders/Surfaces/Planar-Floor.shader`, `Materials/M_Planar-Floor.mat` (the lookup generalised from the Gas-Station's `PlanarReflectionWet.hlsl`; drafted with an AI assistant, 10-27) | Petar Mavrodiev | Workshop | my own |

## Effects (10-27)

| Item | Author | Source | Licence |
|---|---|---|---|
| `Shaders/Light-And-Space/Dust-Back-Scatter.shader` (ported from URP-Tests "Immersive-Spaces/Dust Back-Scatter", Arches, Iteration-5) | Petar Mavrodiev | Workshop / URP-Tests | my own |

## Camera (10-27)

| Item | Author | Source | Licence |
|---|---|---|---|
| `Runtime/CameraBreathing.cs`, `Runtime/ReferenceOverlay.cs`, `Runtime/Reference-Overlay.prefab`, `Materials/M_Reference-Overlay.mat` (drafted with an AI assistant, 10-27; the prefab uses Unity's built-in Quad mesh) | Petar Mavrodiev | Workshop | my own |
| Showcase `Camera-Showcase`: `Showcase-Portrait-Grid.png` (drawn by script), `M_Showcase_Grey.mat`, `M_Showcase_Post.mat` | Petar Mavrodiev | Workshop | my own |

## Terrain (11-03)

| Item | Author | Source | Licence |
|---|---|---|---|
| `Runtime/Terrain/HillTerrainGenerator.cs`, `HillTerrainProfile.cs`, `TerrainSandbox.cs` | Petar Mavrodiev (from his MD4 AY25-26 project, namespace changed) | MD4_26_Mavrodiev | my own |
| `Shaders/Terrain/Terrain-Mono.shader`, `Terrain-Height-Bands.shader` | Petar Mavrodiev (from his Dancerex shaders HeightBandTerrain and HeightBasedTerrain, rewritten on the Library passes with an AI assistant, 11-03) | DancerexDTx | my own |
| `Runtime/Terrain/TerrainLayerRules.cs`, `TerrainTreeAndGrassRules.cs`, `FromToAttribute.cs`, `Editor/Terrain-Rules/` (written from Unity's terrain API with an AI assistant, 11-06; the behaviour studied from the documentation of Staggart Creations' Procedural Terrain Painter and Vegetation Spawner, no code or assets taken) | Petar Mavrodiev | Workshop | my own |
| Showcase `Samples~/Terrain-Showcase/`: textures, terrain layers, materials, meshes and prefabs (all made by script, 11-06) | Petar Mavrodiev | Workshop | my own |

## Foliage wind (11-10)

| Item | Author | Source | Licence |
|---|---|---|---|
| `Shaders/Nature/FoliageWind.shader` | Unity Technologies (URP's `Lit.shader`, URP 17.3 / Unity 6.3), with the wind added by Petar Mavrodiev (AI-assisted) | the Universal Render Pipeline package | Unity Companion License, as URP itself; the changes are my own |
| `Shaders/Nature/FoliageWind.hlsl` | Petar Mavrodiev (AI-assisted) | written for this package | my own |
