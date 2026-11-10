// TerrainTreeAndGrassRules.cs
// The toolbox, Runtime. Namespace Mavrodiev.Toolbox. Petar's, written 2026-11-06 with an AI assistant, on Unity's terrain API.
// In Edit mode: the Place Trees and Place Grass buttons rewrite the terrain's trees and grass from the lists of rows.
// The result is ordinary terrain data: Paint Trees and Paint Details still work on it, until the next press.

using System;
using System.Collections.Generic;
using System.Text;
using UnityEngine;

namespace Mavrodiev.Toolbox
{
    /// <summary>Places a terrain's trees, rocks and grass by rules instead of a brush.
    /// Each press replaces everything of its kind on the terrain, hand-placed copies included.</summary>
    [AddComponentMenu("Mavrodiev/Terrain/Terrain Tree And Grass Rules")]
    [RequireComponent(typeof(Terrain))]
    public class TerrainTreeAndGrassRules : MonoBehaviour
    {
        // The tooltips that trees and grass share.
        private const string NameTip = "Any name you like. It labels this row and appears in the messages.";
        private const string HeightTip = "Place only between these heights, in metres above the bottom of the terrain. World height is not used. The grey line at the top shows how high your ground goes. A big 'to' means all the way up.";
        private const string SlopeTip = "Place only where the ground is this steep, in degrees. 0 flat, 10 a gentle hill, 30 like stairs, 45 too steep for a default character to walk up, 90 a wall.";
        private const string LayerTip = "Optional: leave empty to place on any layer. If set, place only where this Terrain Layer covers at least half the ground. Press Paint Layers first.";
        private const string SeedTip = "Any whole number. The same number gives the same arrangement. Change it to get a different one.";

        private const int TooManyCopies = 20000;     // above this, the report warns that Unity may slow down
        private const float MostDarts = 5000000f;    // keeps a tiny Metres Apart on a huge terrain from freezing the editor
        private const int MostPatchesPerCell = 16;     // Unity keeps no more than this in one cell of the detail map

        [Serializable]
        public class TreeRule
        {
            [Tooltip(NameTip)]
            public string name;

            [Header("What")]
            [Tooltip("What to place. Drag prefabs here from the Project window, not the Hierarchy. With several, each copy picks one at random. A prefab with no LOD Group component gets a Unity warning. It still works, but Random Rotation won't.")]
            public List<GameObject> prefabs = new List<GameObject>();

            [Header("Where")]
            [Tooltip(HeightTip)]
            [FromTo("m")] public Vector2 heightRangeMetres = new Vector2(0f, 1000f);

            [Tooltip(SlopeTip)]
            [FromTo("°")] public Vector2 slopeRangeDegrees = new Vector2(0f, 90f);

            [Tooltip(LayerTip)]
            public TerrainLayer onlyOnLayer;

            [Header("How Many")]
            [Tooltip("Of the spots that could hold a copy, the percent that get one. Lower leaves more gaps.")]
            [Range(0f, 100f)] public float chancePercent = 50f;

            [Tooltip("Copies of this row stay at least this far apart. Bigger means fewer copies. Other rows can still overlap them. Try 3 to 10.")]
            [Min(0.25f)] public float metresApart = 3f;

            [Header("Look")]
            [Tooltip("Each copy gets a random size between these two numbers. 1 is the prefab's own size.")]
            [FromTo("×")] public Vector2 scaleRange = new Vector2(0.8f, 1.2f);

            [Tooltip("Pushes each copy this many metres into the ground. Good for rocks. Try 0 to 0.3.")]
            [Min(0f)] public float sinkMetres = 0f;

            [Tooltip("Turns each copy to a random direction. It works only on a prefab with a LOD Group component. Without one, all copies face the same way.")]
            public bool randomRotation = true;

            [Tooltip(SeedTip)]
            public int seed = 1;
        }

        [Serializable]
        public class GrassRule
        {
            [Tooltip(NameTip)]
            public string name;

            [Header("What")]
            [Tooltip("The easy way: a picture of grass with a transparent background. Each patch is that picture, always turned to face the camera.")]
            public Texture2D texture;

            [Tooltip("A 3D model instead of a picture, from the Project window. If you fill this, the Texture above is ignored. It's best to tick Enable GPU Instancing on its material.")]
            public GameObject prefabInstead;

            [Header("Where")]
            [Tooltip(HeightTip)]
            [FromTo("m")] public Vector2 heightRangeMetres = new Vector2(0f, 1000f);

            [Tooltip(SlopeTip)]
            [FromTo("°")] public Vector2 slopeRangeDegrees = new Vector2(0f, 90f);

            [Tooltip(LayerTip)]
            public TerrainLayer onlyOnLayer;

            [Header("How Many")]
            [Tooltip("Patches of grass per square metre. Try 1 to 5.")]
            [Min(0f)] public float density = 2f;

            [Header("Look")]
            [Tooltip("Each patch gets a random size between these two numbers. For a Texture, in metres. For a prefab, 1 is the model's own size.")]
            [FromTo("×")] public Vector2 scaleRange = new Vector2(0.8f, 1.2f);

            [Tooltip(SeedTip)]
            public int seed = 1;
        }

        [Tooltip("Trees, rocks, bushes: anything placed as separate objects. Unity stores them all as terrain trees, so you can still change them by hand with Paint Trees.")]
        public List<TreeRule> treesAndRocks = new List<TreeRule>();

        [Tooltip("Grass and small plants. Unity draws them only near the camera: if you see nothing, fly the Scene view closer. You can still change them by hand with Paint Details.")]
        public List<GrassRule> grass = new List<GrassRule>();

        // The + button of an empty list adds a row of zeros, not the defaults written above.
        // Only a row that is still empty gets them back: a row in use is never touched.
        private void OnValidate()
        {
            for (int i = 0; i < treesAndRocks.Count; i++)
            {
                TreeRule rule = treesAndRocks[i];
                if (rule.prefabs.Count == 0 && string.IsNullOrEmpty(rule.name)
                    && rule.heightRangeMetres == Vector2.zero && rule.slopeRangeDegrees == Vector2.zero)
                {
                    treesAndRocks[i] = new TreeRule();
                }
            }
            for (int i = 0; i < grass.Count; i++)
            {
                GrassRule rule = grass[i];
                if (rule.texture == null && rule.prefabInstead == null && string.IsNullOrEmpty(rule.name)
                    && rule.heightRangeMetres == Vector2.zero && rule.slopeRangeDegrees == Vector2.zero)
                {
                    grass[i] = new GrassRule();
                }
            }
        }

        /// <summary>Replaces all the terrain's trees with what the rows place. If they place
        /// nothing, the terrain is left as it was. Returns a short report, for the Inspector.</summary>
        public string PlaceTrees()
        {
            var terrain = GetComponent<Terrain>();
            TerrainData data = terrain.terrainData;

            var prefabs = new List<GameObject>();
            var copies = new List<TreeInstance>();
            var report = new StringBuilder();

            for (int i = 0; i < treesAndRocks.Count; i++)
            {
                TreeRule rule = treesAndRocks[i];
                string label = RowLabel(rule.name, i);
                int before = copies.Count;
                PlaceCopies(rule, i, data, prefabs, copies);
                int placed = copies.Count - before;

                if (placed > 0) report.AppendLine($"{label}: {placed} copies.");
                else if (!rule.prefabs.Exists(IsUsablePrefab)) report.AppendLine($"{label}: none. It needs a prefab with a mesh, dragged here from the Project window, not the Hierarchy.");
                else report.AppendLine($"{label}: none. {WhyNoSpots(rule.onlyOnLayer, data)}");
            }

            if (copies.Count == 0) return ("Placed nothing, so the terrain's trees were left as they were.\n" + report).TrimEnd();

            // The terrain stores each different prefab once, in a list it calls prototypes.
            var prototypes = new TreePrototype[prefabs.Count];
            for (int i = 0; i < prefabs.Count; i++) prototypes[i] = new TreePrototype { prefab = prefabs[i] };

            // The old copies go first: they may point at a prototype that is about to disappear.
            int oldCopies = data.treeInstanceCount;
            data.SetTreeInstances(new TreeInstance[0], false);
            data.treePrototypes = prototypes;
            data.SetTreeInstances(copies.ToArray(), false);   // false: don't snap to the ground, the sink would be lost

            terrain.Flush();
            MarkDirty(data);

            string tooMany = copies.Count > TooManyCopies ? "\nThat is a lot of objects and Unity may slow down. Try raising Metres Apart." : "";
            return $"Removed {oldCopies} old copies, placed {copies.Count}.{tooMany}\n{report.ToString().TrimEnd()}";
        }

        /// <summary>Replaces all the terrain's grass with what the rows place. If they place
        /// nothing, the terrain is left as it was. Returns a short report, for the Inspector.</summary>
        public string PlaceGrass()
        {
            var terrain = GetComponent<Terrain>();
            TerrainData data = terrain.terrainData;

            // A terrain made by script may have no detail map yet.
            if (data.detailResolution == 0) data.SetDetailResolution(512, 16);

            var report = new StringBuilder();
            var prototypes = new List<DetailPrototype>();
            var maps = new List<int[,]>();
            int total = 0;

            for (int i = 0; i < grass.Count; i++)
            {
                GrassRule rule = grass[i];
                string label = RowLabel(rule.name, i);

                bool hasPrefab = IsUsablePrefab(rule.prefabInstead);
                if (!hasPrefab && rule.texture == null)
                {
                    report.AppendLine($"{label}: none. It needs a Texture, or a prefab from the Project window.");
                    continue;
                }

                DetailPrototype prototype = MakeDetailPrototype(rule, hasPrefab);
                if (!prototype.Validate(out string problem))
                {
                    report.AppendLine($"{label}: skipped. {problem}");
                    continue;
                }

                // Unity's check above doesn't look at this. Unity 6.6 draws the grass anyway; it's a tip, not an error.
                if (hasPrefab)
                {
                    Material material = rule.prefabInstead.GetComponentInChildren<MeshRenderer>(true).sharedMaterial;
                    if (material != null && !material.enableInstancing) report.AppendLine($"{label}: tip: tick Enable GPU Instancing on the material {material.name}.");
                }

                int[,] map = MakeDetailMap(rule, i, data, out int patches);
                total += patches;
                report.AppendLine(patches > 0 ? $"{label}: {patches} patches." : $"{label}: none. {WhyNoSpots(rule.onlyOnLayer, data)}");

                prototypes.Add(prototype);
                maps.Add(map);
            }

            if (total == 0) return ("Placed nothing, so the terrain's grass was left as it was.\n" + report).TrimEnd();

            // In this mode a cell of the detail map holds a plain count of patches.
            data.SetDetailScatterMode(DetailScatterMode.InstanceCountMode);
            data.detailPrototypes = prototypes.ToArray();
            for (int i = 0; i < maps.Count; i++) data.SetDetailLayer(0, 0, i, maps[i]);

            terrain.Flush();
            MarkDirty(data);

            return $"Replaced the grass, placed {total} patches. You can only see grass within {terrain.detailObjectDistance:0} m of the camera: fly closer if you see nothing.\n{report.ToString().TrimEnd()}";
        }

        //==================== TREES =====================
        private static void PlaceCopies(TreeRule rule, int row, TerrainData data, List<GameObject> prefabs, List<TreeInstance> copies)
        {
            List<GameObject> usable = rule.prefabs.FindAll(IsUsablePrefab);
            if (usable.Count == 0) return;

            // A generator of its own: this row's result then depends only on its seed and its place
            // in the list. The row number keeps two rows with one seed (+ copies it) off the same spots.
            var random = new System.Random(rule.seed + row * 7919);
            float metresApart = Mathf.Max(rule.metresApart, 0.25f);   // [Min] guards the Inspector; this guards a script
            float[,] layerCover = ReadLayerCover(rule.onlyOnLayer, data);
            Vector3 size = data.size;

            // Throw random darts at the terrain. Three for each area of one spacing squared: enough to nearly fill it.
            int darts = Mathf.CeilToInt(Mathf.Min(3f * size.x * size.z / (metresApart * metresApart), MostDarts));

            // The spots taken so far, sorted into squares one spacing wide, so each dart
            // only has to look at the squares next to it.
            var taken = new Dictionary<Vector2Int, List<Vector2>>();

            for (int i = 0; i < darts; i++)
            {
                float u = (float)random.NextDouble();   // u and v run 0…1 across the terrain
                float v = (float)random.NextDouble();

                var spot = new Vector2(u * size.x, v * size.z);
                var square = new Vector2Int(Mathf.FloorToInt(spot.x / metresApart), Mathf.FloorToInt(spot.y / metresApart));
                if (TooClose(taken, spot, square, metresApart)) continue;
                if (!FitsRules(rule.heightRangeMetres, rule.slopeRangeDegrees, layerCover, data, u, v)) continue;

                // The spot counts as taken even if the dice below leave it empty. That is what
                // makes the chance honest: 30% gives about 30% of a full row, with real gaps.
                if (!taken.TryGetValue(square, out List<Vector2> inSquare))
                {
                    inSquare = new List<Vector2>();
                    taken[square] = inSquare;
                }
                inSquare.Add(spot);

                if (random.NextDouble() * 100.0 >= rule.chancePercent) continue;

                // A copy doesn't hold its prefab, only the prefab's number in the terrain's list.
                GameObject prefab = usable[random.Next(usable.Count)];
                int prefabIndex = prefabs.IndexOf(prefab);
                if (prefabIndex < 0)
                {
                    prefabs.Add(prefab);
                    prefabIndex = prefabs.Count - 1;
                }

                float scale = Mathf.Max(Mathf.Lerp(rule.scaleRange.x, rule.scaleRange.y, (float)random.NextDouble()), 0.01f);
                float height = (data.GetInterpolatedHeight(u, v) - rule.sinkMetres) / size.y;

                copies.Add(new TreeInstance
                {
                    position = new Vector3(u, Mathf.Max(height, 0f), v),   // all three 0…1 across the terrain
                    prototypeIndex = prefabIndex,
                    widthScale = scale,
                    heightScale = scale,
                    rotation = rule.randomRotation ? (float)random.NextDouble() * Mathf.PI * 2f : 0f,
                    color = Color.white,
                    lightmapColor = Color.white,
                });
            }
        }

        private static bool TooClose(Dictionary<Vector2Int, List<Vector2>> taken, Vector2 spot, Vector2Int square, float metresApart)
        {
            for (int y = square.y - 1; y <= square.y + 1; y++)
            {
                for (int x = square.x - 1; x <= square.x + 1; x++)
                {
                    if (!taken.TryGetValue(new Vector2Int(x, y), out List<Vector2> inSquare)) continue;

                    foreach (Vector2 other in inSquare)
                    {
                        if (Vector2.Distance(spot, other) < metresApart) return true;
                    }
                }
            }
            return false;
        }

        //==================== GRASS =====================
        // Unity calls grass "details". A prototype is one kind of grass, and a detail map says
        // how many patches of it grow in each small square (cell) of the terrain.
        private static DetailPrototype MakeDetailPrototype(GrassRule rule, bool hasPrefab)
        {
            float smallest = Mathf.Max(Mathf.Min(rule.scaleRange.x, rule.scaleRange.y), 0.01f);
            float biggest = Mathf.Max(rule.scaleRange.x, rule.scaleRange.y, smallest);

            var prototype = new DetailPrototype
            {
                minWidth = smallest,
                maxWidth = biggest,
                minHeight = smallest,
                maxHeight = biggest,
                healthyColor = Color.white,   // white: the prefab or texture keeps its own colours
                dryColor = Color.white,
                positionJitter = 1f,          // scatter patches inside their cell, in projects that use Unity's newer grass distribution
            };

            if (hasPrefab)
            {
                prototype.prototype = rule.prefabInstead;
                prototype.usePrototypeMesh = true;
                prototype.renderMode = DetailRenderMode.VertexLit;
                prototype.useInstancing = true;
            }
            else
            {
                prototype.prototypeTexture = rule.texture;
                prototype.usePrototypeMesh = false;
                prototype.renderMode = DetailRenderMode.GrassBillboard;
            }

            return prototype;
        }

        // One count per cell of the terrain's detail map. Unity indexes it [y, x].
        private static int[,] MakeDetailMap(GrassRule rule, int row, TerrainData data, out int patches)
        {
            var random = new System.Random(rule.seed + row * 7919);   // see PlaceCopies
            float[,] layerCover = ReadLayerCover(rule.onlyOnLayer, data);
            int resolution = data.detailResolution;
            var map = new int[resolution, resolution];
            patches = 0;

            // How many patches one cell should hold. Its fraction becomes a dice roll per cell.
            // The roll comes first: most cells stop there, before asking the terrain for a height and a slope.
            float cellArea = data.size.x * data.size.z / (resolution * resolution);
            float patchesPerCell = rule.density * cellArea;
            int whole = Mathf.FloorToInt(patchesPerCell);
            float fraction = patchesPerCell - whole;

            for (int y = 0; y < resolution; y++)
            {
                for (int x = 0; x < resolution; x++)
                {
                    int count = whole + (random.NextDouble() < fraction ? 1 : 0);
                    if (count == 0) continue;

                    if (FitsRules(rule.heightRangeMetres, rule.slopeRangeDegrees, layerCover, data, (x + 0.5f) / resolution, (y + 0.5f) / resolution))
                    {
                        map[y, x] = Mathf.Min(count, MostPatchesPerCell);
                        patches += map[y, x];
                    }
                }
            }

            return map;
        }

        //==================== SHARED =====================
        // u and v run 0…1 across the terrain. layerCover is null when the row has no layer rule.
        private static bool FitsRules(Vector2 heightRange, Vector2 slopeRange, float[,] layerCover, TerrainData data, float u, float v)
        {
            if (!InRange(data.GetInterpolatedHeight(u, v), heightRange)) return false;
            if (!InRange(data.GetSteepness(u, v), slopeRange)) return false;
            if (layerCover == null) return true;

            // "Mostly this layer": read one pixel of the splatmap, and count it from one half up.
            int last = layerCover.GetLength(0) - 1;
            return layerCover[Mathf.RoundToInt(v * last), Mathf.RoundToInt(u * last)] >= 0.5f;
        }

        private static bool InRange(float value, Vector2 range)
        {
            return value >= Mathf.Min(range.x, range.y) && value <= Mathf.Max(range.x, range.y);   // a range typed backwards still works
        }

        // How much of this layer shows at each pixel of the splatmap, read once per row.
        // The same layer may be on the terrain twice, so its shares add up. Null: no layer rule.
        private static float[,] ReadLayerCover(TerrainLayer layer, TerrainData data)
        {
            if (layer == null) return null;

            int resolution = data.alphamapResolution;
            float[,,] splatmap = data.GetAlphamaps(0, 0, resolution, resolution);
            TerrainLayer[] terrainLayers = data.terrainLayers;
            var cover = new float[resolution, resolution];

            for (int k = 0; k < terrainLayers.Length; k++)
            {
                if (terrainLayers[k] != layer) continue;

                for (int y = 0; y < resolution; y++)
                {
                    for (int x = 0; x < resolution; x++) cover[y, x] += splatmap[y, x, k];
                }
            }
            return cover;
        }

        // A prefab from the Project window with something to draw. A scene object from the
        // Hierarchy looks the same to the slot, but a terrain asset can't keep hold of it.
        private static bool IsUsablePrefab(GameObject prefab)
        {
            return prefab != null && !prefab.scene.IsValid() && prefab.GetComponentInChildren<MeshRenderer>(true) != null;
        }

        private static string RowLabel(string name, int row)
        {
            return string.IsNullOrEmpty(name) ? $"Row {row + 1}" : name;
        }

        private static string WhyNoSpots(TerrainLayer onlyOnLayer, TerrainData data)
        {
            if (onlyOnLayer != null && Array.IndexOf(data.terrainLayers, onlyOnLayer) < 0)
            {
                return "Its Only On Layer is not on this terrain. Press Paint Layers first.";
            }
            return $"No spot fits. The ground here goes from {data.bounds.min.y:0.#} to {data.bounds.max.y:0.#} m high.";
        }

        private static void MarkDirty(TerrainData data)
        {
#if UNITY_EDITOR
            if (!Application.isPlaying) UnityEditor.EditorUtility.SetDirty(data);
#endif
        }
    }
}
