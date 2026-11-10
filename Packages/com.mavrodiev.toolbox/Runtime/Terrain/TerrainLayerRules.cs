// TerrainLayerRules.cs
// The toolbox, Runtime. Namespace Mavrodiev.Toolbox. Petar's, written 2026-11-06 with an AI assistant, on Unity's terrain API.
// In Edit mode: the Paint Layers button rewrites how much of each layer shows at every point of the terrain (Unity calls this the splatmap).
// The result is an ordinary painted terrain: Paint Texture still works on it, until the next Paint Layers.

using System.Collections.Generic;
using System.Text;
using UnityEngine;

namespace Mavrodiev.Toolbox
{
    /// <summary>Paints a terrain's layers by rules instead of a brush. The base layer fills the
    /// whole terrain. Then each row paints over it in turn, like coats of paint, wherever its
    /// height and slope ranges say so. A later row covers the earlier ones.</summary>
    [AddComponentMenu("Mavrodiev/Terrain/Terrain Layer Rules")]
    [RequireComponent(typeof(Terrain))]
    public class TerrainLayerRules : MonoBehaviour
    {
        [System.Serializable]
        public class LayerRule
        {
            [Tooltip("Any name you like. It labels this row and appears in the messages.")]
            public string name;

            [Tooltip("The Terrain Layer this row paints. It must be a Terrain Layer asset, not a picture.")]
            public TerrainLayer layer;

            [Header("Where")]
            [Tooltip("Paint only between these heights, in metres above the bottom of the terrain. World height is not used. The grey line at the top shows how high your ground goes. A big 'to' means all the way up.")]
            [FromTo] public Vector2 heightRangeMetres = new Vector2(0f, 1000f);

            [Tooltip("Past the range, the layer fades away over this many metres. 0 is a hard line. Try 1 to 3.")]
            [Min(0f)] public float heightFadeMetres = 1f;

            [Tooltip("Paint only where the ground is this steep, in degrees. 0 flat, 10 a gentle hill, 30 like stairs, 45 too steep for a default character to walk up, 90 a wall.")]
            [FromTo] public Vector2 slopeRangeDegrees = new Vector2(0f, 90f);

            [Tooltip("Past the range, the layer fades away over this many degrees. 0 is a hard line. Try 3 to 8.")]
            [Min(0f)] public float slopeFadeDegrees = 5f;

            [Header("Edge")]
            [Tooltip("Makes this layer's edge wavy and patchy instead of smooth. 0 is off. Try 0.6. It works only inside a fade: with a fade of 0 nothing changes, and a wider fade gives bigger waves.")]
            [Range(0f, 0.9f)] public float edgeNoise = 0f;

            [Tooltip("How wide the waves are, in metres. Small is busy, large is calm. Try 3 to 10.")]
            [Min(0.1f)] public float noiseSizeMetres = 5f;

            /// <summary>How strongly this row covers a spot: 0 not at all, 1 fully.</summary>
            public float Mask(float height, float slope, float noise)
            {
                float mask = Band(height, heightRangeMetres, heightFadeMetres) * Band(slope, slopeRangeDegrees, slopeFadeDegrees);

                // Noise decides how far the layer reaches inside the fade: a spot with low noise
                // shows it earlier, a spot with high noise later. Where the mask is fully 0 or
                // fully 1 it changes nothing, so it never leaves specks. The slider stops at 0.9
                // because at 1 the two ends of this range would meet and the row would paint nothing.
                float threshold = Mathf.Clamp01(noise) * edgeNoise;
                mask = Mathf.InverseLerp(threshold, threshold + 1f - edgeNoise, mask);

                // Round off the fade's two ends, so it starts and stops without a visible line.
                return Mathf.SmoothStep(0f, 1f, mask);
            }

            // 1 inside the range, fading to 0 over the fade on each side of it.
            private static float Band(float value, Vector2 range, float fade)
            {
                float from = Mathf.Min(range.x, range.y);   // a range typed backwards still works
                float to = Mathf.Max(range.x, range.y);

                if (fade <= 0f) return value >= from && value <= to ? 1f : 0f;

                // The second one runs backwards on purpose: it climbs from 0 above the range to 1 at its top.
                return Mathf.InverseLerp(from - fade, from, value) * Mathf.InverseLerp(to + fade, to, value);
            }
        }

        [Tooltip("The layer that fills the whole terrain. The rows below paint over it. It must be a Terrain Layer asset, not a picture: make one with the Create menu in the Project window.")]
        public TerrainLayer baseLayer;

        [Tooltip("Painted one after another from the first row to the last, like coats of paint. A later row covers the earlier ones. A row left at its full range covers everything before it, so narrow the range.")]
        public List<LayerRule> layersOnTop = new List<LayerRule>();

        // The + button of an empty list adds a row of zeros, not the defaults written above.
        // Only a row that is still empty gets them back: a row in use is never touched.
        private void OnValidate()
        {
            for (int i = 0; i < layersOnTop.Count; i++)
            {
                LayerRule rule = layersOnTop[i];
                if (rule.layer == null && string.IsNullOrEmpty(rule.name)
                    && rule.heightRangeMetres == Vector2.zero && rule.slopeRangeDegrees == Vector2.zero)
                {
                    layersOnTop[i] = new LayerRule();
                }
            }
        }

        /// <summary>Rewrites the terrain's layers and splatmap from the rules.
        /// Returns a short report of what happened, for the Inspector.</summary>
        public string PaintLayers()
        {
            var terrain = GetComponent<Terrain>();
            TerrainData data = terrain.terrainData;

            if (baseLayer == null) return "Choose a Base Layer first. Nothing was painted.";

            var report = new StringBuilder();

            // Keep only the rows that have a layer to paint.
            var rows = new List<LayerRule>();
            for (int i = 0; i < layersOnTop.Count; i++)
            {
                if (layersOnTop[i].layer != null) rows.Add(layersOnTop[i]);
                else report.AppendLine($"Row {i + 1}: no Terrain Layer, skipped.");
            }

            // The terrain's own list of layers: the base first, then the rows.
            var terrainLayers = new TerrainLayer[rows.Count + 1];
            terrainLayers[0] = baseLayer;
            for (int i = 0; i < rows.Count; i++) terrainLayers[i + 1] = rows[i].layer;
            data.terrainLayers = terrainLayers;

            // The splatmap: a hidden picture stretched over the terrain. Each of its pixels stores
            // how much of each layer shows there. Unity indexes it [y, x, layer].
            int resolution = data.alphamapResolution;
            var splatmap = new float[resolution, resolution, terrainLayers.Length];
            var shares = new float[terrainLayers.Length];
            Vector3 origin = terrain.transform.position;
            Vector3 size = data.size;

            for (int y = 0; y < resolution; y++)
            {
                float v = y / (resolution - 1f);   // u and v run 0…1 across the terrain

                for (int x = 0; x < resolution; x++)
                {
                    float u = x / (resolution - 1f);
                    float height = data.GetInterpolatedHeight(u, v);
                    float slope = data.GetSteepness(u, v);

                    splatmap[y, x, 0] = 1f;   // the base layer fills everything

                    // Stack the rows: each one takes its share away from those beneath it,
                    // so the weights of a pixel always add up to 1.
                    for (int i = 0; i < rows.Count; i++)
                    {
                        LayerRule row = rows[i];
                        float noise = 0f;
                        if (row.edgeNoise > 0f)
                        {
                            float noiseSize = Mathf.Max(row.noiseSizeMetres, 0.1f);
                            noise = Mathf.PerlinNoise(
                                (origin.x + u * size.x) / noiseSize + i * 37f,   // shift each row's noise, so rows don't wave together
                                (origin.z + v * size.z) / noiseSize);
                        }

                        float mask = row.Mask(height, slope, noise);

                        for (int below = 0; below <= i; below++) splatmap[y, x, below] *= 1f - mask;
                        splatmap[y, x, i + 1] = mask;
                    }

                    for (int k = 0; k < shares.Length; k++) shares[k] += splatmap[y, x, k];
                }
            }

            data.SetAlphamaps(0, 0, splatmap);
            data.SetBaseMapDirty();

#if UNITY_EDITOR
            if (!Application.isPlaying) UnityEditor.EditorUtility.SetDirty(data);
#endif

            // How much of the terrain each layer ended up with.
            float pixels = resolution * resolution;
            report.Insert(0, $"{baseLayer.name} (base): {100f * shares[0] / pixels:0}%\n");
            for (int i = 0; i < rows.Count; i++)
            {
                float percent = 100f * shares[i + 1] / pixels;
                string label = string.IsNullOrEmpty(rows[i].name) ? rows[i].layer.name : rows[i].name;
                report.AppendLine(percent >= 0.5f
                    ? $"{label}: {percent:0}%"
                    : $"{label}: 0%. Its ranges fit nowhere on this ground, or a later row covers it.");
            }
            return report.ToString().TrimEnd();
        }
    }
}
