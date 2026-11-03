// HillTerrainGenerator.cs
// The toolbox, Runtime. Namespace Mavrodiev.Toolbox. Petar's, from the MD4 AY25-26 project (Ludocore), moved here 2026-11-03.
// In Edit mode: the component's menu (⋮) › Generate writes the hills into the terrain's TerrainData asset.
// TerrainDrift and TerrainBreathe (named below) stayed in the MD4 project: they need DOTween.

using UnityEngine;

namespace Mavrodiev.Toolbox
{
    /// <summary>Bakes a soft Perlin "sea of hills" heightmap onto a Unity Terrain
    /// from a swappable HillTerrainProfile. Generate() takes an optional
    /// additive noise offset, used by TerrainDrift to slide the hill
    /// pattern at runtime without mutating the profile asset.</summary>
    [AddComponentMenu("Mavrodiev/Terrain/Hill Terrain Generator")]
    [RequireComponent(typeof(Terrain))]
    [RequireComponent(typeof(TerrainSandbox))]
    public class HillTerrainGenerator : MonoBehaviour
    {
        //==================== SCENE REFERENCES =====================
        [Header("Scene References")]
        [Tooltip("Terrain to write the heightmap into. Auto-fetched from this GameObject if empty.")]
        [SerializeField] private Terrain terrain;

        //==================== PROFILE =====================
        [Header("Profile")]
        [Tooltip("Tuning data for the hill shape, size, and noise.")]
        [SerializeField] private HillTerrainProfile profile;

        //==================== BEHAVIOUR =====================
        [Header("Behaviour")]
        [Tooltip("Call Generate() in Start().")]
        [SerializeField] private bool generateOnStart = true;

        //==================== STATE =====================
        // Reused across Generate() calls so per-tick TerrainDrift rebuilds don't allocate a
        // fresh res*res float array (~1 MB at 513) every tick. Reallocated only when res changes.
        private float[,] _heights;

        //==================== LIFECYCLE =====================
        private void Reset()
        {
            terrain = GetComponent<Terrain>();
        }

        private void Start()
        {
            if (generateOnStart) Generate();
        }

        //==================== INPUTS =====================
        /// <summary>Full rebuild of the terrain heightmap from the profile.</summary>
        [ContextMenu("Generate")]
        public void Generate() => Generate(Vector2.zero);

        /// <summary>Full rebuild with an additive noise offset on top of the profile's
        /// static noiseOffset. Used by TerrainDrift to animate the hill pattern.</summary>
        public void Generate(Vector2 additionalNoiseOffset)
        {
            if (!terrain) terrain = GetComponent<Terrain>();
            if (!terrain || !profile) return;

            var data = terrain.terrainData;
            int res = profile.heightmapResolution;

            // Setting heightmapResolution reallocates the heightmap, so skip when unchanged.
            if (data.heightmapResolution != res) data.heightmapResolution = res;

            // Skip when unchanged so per-tick drift rebuilds don't re-touch size — and don't
            // stomp a TerrainBreathe that's mid-stretch on size.y.
            if (data.size != profile.terrainSize) data.size = profile.terrainSize;

            // Mathf.PerlinNoise has no seed parameter, so we shift the sample point.
            var rng = new System.Random(profile.seed);
            float seedOffsetX = (float)(rng.NextDouble() * 200000.0 - 100000.0);
            float seedOffsetY = (float)(rng.NextDouble() * 200000.0 - 100000.0);

            float maxAmplitude = ComputeMaxAmplitude(profile.octaves, profile.persistence);
            float invMaxAmplitude = maxAmplitude > 0f ? 1f / maxAmplitude : 0f;

            float width = profile.terrainSize.x;
            float depth = profile.terrainSize.z;
            float invResMinusOne = 1f / (res - 1);
            float baseOffsetX = profile.noiseOffset.x + additionalNoiseOffset.x;
            float baseOffsetY = profile.noiseOffset.y + additionalNoiseOffset.y;

            if (_heights == null || _heights.GetLength(0) != res) _heights = new float[res, res];
            float[,] heights = _heights;

            for (int y = 0; y < res; y++)
            {
                float v = y * invResMinusOne;
                float worldZ = v * depth + baseOffsetY;

                for (int x = 0; x < res; x++)
                {
                    float u = x * invResMinusOne;
                    float worldX = u * width + baseOffsetX;

                    float sum = 0f;
                    float amplitude = 1f;
                    float frequency = profile.baseFrequency;

                    for (int o = 0; o < profile.octaves; o++)
                    {
                        float sx = worldX * frequency + seedOffsetX;
                        float sz = worldZ * frequency + seedOffsetY;
                        sum += Mathf.PerlinNoise(sx, sz) * amplitude;

                        amplitude *= profile.persistence;
                        frequency *= profile.lacunarity;
                    }

                    float normalised = Mathf.Clamp01(sum * invMaxAmplitude);
                    float shaped = Mathf.Clamp01(profile.heightCurve.Evaluate(normalised));

                    // Unity expects [y, x] indexing for SetHeights.
                    heights[y, x] = shaped;
                }
            }

            data.SetHeights(0, 0, heights);

#if UNITY_EDITOR
            // Persist ContextMenu bakes done outside Play mode. Never dirty during play —
            // TerrainSandbox swaps in a throwaway clone there, so it'd be pointless work.
            if (!Application.isPlaying) UnityEditor.EditorUtility.SetDirty(data);
#endif
        }

        //==================== PRIVATE =====================
        private static float ComputeMaxAmplitude(int octaves, float persistence)
        {
            float sum = 0f;
            float amplitude = 1f;
            for (int i = 0; i < octaves; i++)
            {
                sum += amplitude;
                amplitude *= persistence;
            }
            return sum;
        }
    }
}
