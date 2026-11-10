# Third Party Notices

Every asset or piece of code in this package that is not my own: its author, source and licence.

The presentation kit uses pieces of Unity's Scriptable Render Pipeline Core samples (version 17.6.0) as **stand-ins**: the info stands, the name holders, the floor spotlights and their materials. They are to be replaced with my own pieces later.

| Item | Author | Source | Licence |
|---|---|---|---|
| `Presentation/Models/` (`InfosStand`, `NameHolder`, `SamplesFloorSpotlight`, `SamplesSpotlightModel`, `BackgroundMesh`, `Curtain`) | Unity Technologies | SRP Core package samples, `com.unity.render-pipelines.core` 17.6.0 | Unity Companion License (stand-ins, to be replaced) |
| `Presentation/Materials/Samples_*.mat`, `SamplesSpotlightEmissive.mat` | Unity Technologies | SRP Core samples 17.6.0 | Unity Companion License (stand-ins, to be replaced) |
| `Presentation/Shaders/` (`SamplesCrossLit`, `SamplesCyclo`, `SamplesEmissive`, `SamplesGenericTextured`) | Unity Technologies | SRP Core samples 17.6.0 | Unity Companion License (stand-ins, to be replaced) |
| `Presentation/Textures/Samples_FractalNoises.png` | Unity Technologies | SRP Core samples 17.6.0 | Unity Companion License (stand-ins, to be replaced) |
| `Presentation/Scripts/SamplesLinkLightToEmissive.cs` | Unity Technologies | SRP Core samples 17.6.0 | Unity Companion License (stand-in, to be replaced) |
| `Presentation/Fonts/SamplesLit_Inter.shadergraph`, `TMP_Node.hlsl` | Unity Technologies | SRP Core samples 17.6.0 | Unity Companion License (stand-ins, to be replaced) |
| `Presentation/Fonts/Inter-Regular SDF.asset` (the Inter typeface, as a TextMesh Pro font asset) | Rasmus Andersson (Inter); font asset by Unity Technologies | https://rsms.me/inter/ via the SRP Core samples 17.6.0 | SIL Open Font License 1.1 (the typeface) [?: check the licence file Unity ships with it] |

My own pieces in the kit: `Presentation/Prefabs/Human-Silhouette-1.8m.prefab` with `M_Kit_Silhouette`, the floor grid (`M_Floor-Grid-1m`, `T_Grid-1m.png`), and the layer colours `M_Layer-Reference`, `M_Layer-Training`, `M_Layer-Exercise` (placeholders).

## Sample 03 · Textures (`Samples~/03-Textures/`, now `Assets/_Samples/playground/03-Textures/`)

| Item | Author | Source | Licence |
|---|---|---|---|
| `Make-A-Material/Raw-Sets/Concrete-Panels/` (renamed copy of Concrete008, 1K) | ambientCG | https://ambientcg.com/view?id=Concrete008 | CC0 1.0 |
| `Make-A-Material/Raw-Sets/Stone-Paving/` (renamed copy of PavingStones038, 1K) | ambientCG | https://ambientcg.com/view?id=PavingStones038 | CC0 1.0 |
| `Textures/T_Brick_128`, `T_Brick_512`, `T_Brick_1024` (copies of Bricks051's colour map, imported at three sizes) | ambientCG | https://ambientcg.com/view?id=Bricks051 | CC0 1.0 |
| `Textures/T_Pool_Normal_Imported-As-Default`, `T_Pool_Occlusion_sRGB-On` (copies of Tiles132A's maps, set up wrong on purpose) | ambientCG | https://ambientcg.com/view?id=Tiles132A | CC0 1.0 |
| `Textures/T_Pool-Tiles_Height.png` (derived by script from Tiles132A's occlusion map) | ambientCG, derived | https://ambientcg.com/view?id=Tiles132A | CC0 1.0 |
| `Textures/T_Pool_Roughness-In-Smoothness-Slot.png`, `T_Unique-Picture.png`, `T_Large-Variation.png`, `T_Concrete_Painted-Shadow.png` | [?] made by script in the Workshop (10-20), from the CC0 sets above [?] | Workshop | [?] to confirm |

## Sample 10 · Camera (`Assets/_Samples/playground/10-Camera/`)

| Item | Author | Source | Licence |
|---|---|---|---|
| `Camera/References/22-Road-Streetlights-In-Blue-Fog.jpg`, `Camera/References/29-Sign-Red-Neon-On-A-Pole.jpg` (copied from the Atmosphere-Gallery's references) | [?] | [?] not recorded | [?] clear before a public release |

## 14 · Soft Surfaces and 15 · Terrain (11-06)

These samples hold only their own scenes, terrain data, materials and sample-local copies of Terrain Layers; the plants, rocks, textures and heightmaps they use are in the Asset Library, credited in its notices (the plants are CC BY 4.0, by LOLIPOP).

| Item | Author | Source | Licence |
|---|---|---|---|
| `14-Soft-Surfaces/Soft-Surfaces/T_Heightmap-Mountain.png`, `15-Terrain/Terrain-Manual/T_Brush-Mountain.png` (grey copies made by script) | ambientCG (Terrain 002) | https://ambientcg.com/view?id=Terrain002 | CC0 1.0 |
