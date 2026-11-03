// HillTerrainProfile.cs
// The toolbox, Runtime. Namespace Mavrodiev.Toolbox. Petar's, from the MD4 AY25-26 project (Ludocore), moved here 2026-11-03.
// Create › Mavrodiev › Terrain › Hill Terrain Profile.

using UnityEngine;

namespace Mavrodiev.Toolbox
{
    /// <summary>Tuning profile for HillTerrainGenerator — soft Perlin "sea of hills"
    /// shape, no erosion or ridges. Swap profiles per scene to change mood.</summary>
    [CreateAssetMenu(menuName = "Mavrodiev/Terrain/Hill Terrain Profile", fileName = "Hill-Profile")]
    public class HillTerrainProfile : ScriptableObject
    {
        //==================== PATCH =====================
        [Header("Patch")]
        [Tooltip("Terrain size in metres (X = width, Y = max height, Z = depth). Width/depth are clamped to 1000.")]
        public Vector3 terrainSize = new Vector3(500f, 30f, 500f);

        [Tooltip("Heightmap resolution. Must be 2^n + 1 (33, 65, 129, 257, 513, 1025, 2049, 4097). Snapped on validate.")]
        public int heightmapResolution = 513;

        //==================== NOISE =====================
        [Header("Noise")]
        [Tooltip("Deterministic seed — same seed gives the same hills.")]
        public int seed = 0;

        [Tooltip("Base sample frequency. Small (~0.002) = wide rolling hills; large (~0.02) = tight bumps.")]
        [Min(0.0001f)]
        public float baseFrequency = 0.005f;

        [Tooltip("Number of fBm noise layers stacked.")]
        [Range(1, 8)]
        public int octaves = 4;

        [Tooltip("Amplitude falloff per octave (≈0.5 is typical).")]
        [Range(0f, 1f)]
        public float persistence = 0.5f;

        [Tooltip("Frequency multiplier per octave (≈2.0 is typical).")]
        [Min(1f)]
        public float lacunarity = 2f;

        [Tooltip("Remaps raw noise 0..1 → 0..1 before scaling by terrainSize.Y. " +
                 "Linear = even rolling; S-curve = plateaus; ease-in = mostly flat with rare tall hills.")]
        public AnimationCurve heightCurve = AnimationCurve.Linear(0f, 0f, 1f, 1f);

        //==================== SAMPLING =====================
        [Header("Sampling")]
        [Tooltip("Static world-space offset added to noise sampling. Slide the same seed through the noise field to find a nice patch without re-rolling.")]
        public Vector2 noiseOffset = Vector2.zero;

        //==================== VALIDATION =====================
        private void OnValidate()
        {
            terrainSize.x = Mathf.Clamp(terrainSize.x, 1f, 1000f);
            terrainSize.z = Mathf.Clamp(terrainSize.z, 1f, 1000f);
            terrainSize.y = Mathf.Max(0.01f, terrainSize.y);

            // Snap to nearest valid 2^n + 1 in [33, 4097].
            int n = Mathf.Clamp(Mathf.RoundToInt(Mathf.Log(Mathf.Max(2, heightmapResolution - 1), 2f)), 5, 12);
            heightmapResolution = (1 << n) + 1;
        }
    }
}
