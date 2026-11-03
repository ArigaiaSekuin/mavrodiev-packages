// TerrainSandbox.cs
// The toolbox, Runtime. Namespace Mavrodiev.Toolbox. Petar's, from the MD4 AY25-26 project (Ludocore), moved here 2026-11-03.

using UnityEngine;

namespace Mavrodiev.Toolbox
{
    /// <summary>Protects a Terrain's on-disk TerrainData asset from runtime edits. In Play
    /// mode it swaps the Terrain (and its TerrainCollider) onto a throwaway clone of the
    /// TerrainData, so HillTerrainGenerator / TerrainDrift / TerrainBreathe mutate the clone
    /// and never the saved asset. The terrain therefore always resets to its initial state on
    /// Stop — even mid-tween or while looping, where no OnComplete ever fires.
    ///
    /// Runs very early (DefaultExecutionOrder) so the clone exists before any effect mutates
    /// it. No effect in builds: there the asset is read-only on disk and discarded on quit, so
    /// the clone would be pure overhead.</summary>
    [AddComponentMenu("Mavrodiev/Terrain/Terrain Sandbox")]
    [DefaultExecutionOrder(-1000)]
    [RequireComponent(typeof(Terrain))]
    public class TerrainSandbox : MonoBehaviour
    {
        private Terrain _terrain;
        private TerrainCollider _collider;
        private TerrainData _original;
        private TerrainData _clone;

        /// <summary>The untouched, on-disk TerrainData. Effects that want a deterministic
        /// "reset to original" can read this rather than holding their own snapshot.</summary>
        public TerrainData Original => _original;

        private void Awake()
        {
            // Builds don't persist asset edits and restart per session — skip the clone there.
            if (!Application.isEditor) return;

            _terrain = GetComponent<Terrain>();
            _collider = GetComponent<TerrainCollider>();
            if (!_terrain || _terrain.terrainData == null) return;

            _original = _terrain.terrainData;
            _clone = Instantiate(_original);
            _clone.name = _original.name + " (Runtime Clone)";

            _terrain.terrainData = _clone;
            if (_collider) _collider.terrainData = _clone;

#if UNITY_EDITOR
            // ExitingPlayMode fires regardless of Enter-Play-Mode-Options (Domain/Scene reload),
            // and after the last frame's Update — so no stray tween setter can run against the
            // restored original. More reliable than OnDisable for the authoritative restore.
            UnityEditor.EditorApplication.playModeStateChanged += OnPlayModeChanged;
#endif
        }

#if UNITY_EDITOR
        private void OnPlayModeChanged(UnityEditor.PlayModeStateChange state)
        {
            if (state != UnityEditor.PlayModeStateChange.ExitingPlayMode) return;
            RestoreOriginal();
            UnityEditor.EditorApplication.playModeStateChanged -= OnPlayModeChanged;
        }
#endif

        private void OnDestroy()
        {
#if UNITY_EDITOR
            UnityEditor.EditorApplication.playModeStateChanged -= OnPlayModeChanged;
#endif
            RestoreOriginal();
        }

        private void RestoreOriginal()
        {
            if (_original == null) return;

            if (_terrain) _terrain.terrainData = _original;
            if (_collider) _collider.terrainData = _original;

            if (_clone) { Destroy(_clone); _clone = null; }
            _original = null;
        }
    }
}
