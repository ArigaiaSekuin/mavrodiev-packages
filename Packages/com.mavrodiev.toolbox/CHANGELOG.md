# Changelog

## 1.3.1 — 2026-11-10
Fix: Foliage Wind was not SRP Batcher compatible (its wind settings sat outside the material buffer), so with the GPU Resident Drawer on, Unity refused to draw the plants. The wind settings now sit in the buffer, through the shader's own copy of URP's Lit input.

## 1.3.0 — 2026-11-10
Foliage wind: a new shader, Mavrodiev/Foliage Wind (URP Lit with a sway in its vertex passes; roots still, tips moving), used by the asset library's plants. The terrain rule tools' Inspectors made clearer: each row folds under its number and name, short labels (Height, Slope, Spacing, Per m²…), and ranges read "from [ ] to [ ] m" or "°".

## 1.2.0 — 2026-11-10
Terrain by rules: Terrain Layer Rules paints layers by height and slope; Terrain Tree And Grass Rules places trees, rocks and grass by height, slope and layer. Both write ordinary terrain data. New sample: Terrain Showcase.

## 1.1.0 — 2026-11-03
The tools: camera breathing, planar reflection, reference overlay, ripple flipbook, terrain helpers, the mesh-health and texel-density windows, material from texture maps, and the shaders. Eight showcase samples, one per tool family. Needs URP and ProBuilder.

## 1.0.0 — 2026-10-27
First version: the empty package.
