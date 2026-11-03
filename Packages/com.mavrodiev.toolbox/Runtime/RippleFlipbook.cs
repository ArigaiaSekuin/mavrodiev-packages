// RippleFlipbook - steps a material's normal map through a set of frames: rain ripples on wet ground.
// From Petar's Gas-Station (URP-Tests, Iteration-1-HDRP-Port/Scripts/RippleFlipbook.cs), moved into the toolbox.
// Changes from the original (DRAFT 2026-10-27, check in the editor):
//   - namespace Mavrodiev.Toolbox, a menu entry, tooltips
//   - the default property is Normal_Map: URP's decal shaders (Shader Graphs/Decal and Mavrodiev/Weathering/Decal-Masked)
//     name the normal map Normal_Map, not _NormalMap (checked in URP 17.6's Decal.shadergraph and in Decal-Masked)
//   - with no material set, it finds the Decal Projector or the Renderer on the same GameObject
//   - in Play mode it animates a copy of the material (Play mode changes are thrown away anyway), so the asset is untouched
//   - in Edit mode it animates the material asset itself, as before, only when Animate In Edit Mode is on
//     (the asset changes on disk: keep it in the scene's own folder, never in a read-only package)
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Mavrodiev.Toolbox
{
    [ExecuteAlways]
    [AddComponentMenu("Mavrodiev/Ripple Flipbook")]
    public class RippleFlipbook : MonoBehaviour
    {
        [Tooltip("The material whose texture is stepped. Leave empty to use the Decal Projector or the Renderer on this GameObject.")]
        public Material material;

        [Tooltip("The frames, in order. They play in a loop.")]
        public Texture2D[] frames;

        [Tooltip("How many frames are shown each second.")]
        public float framesPerSecond = 20f;

        [Tooltip("The texture property to step. URP's decal shaders: Normal_Map. URP Lit: _BumpMap.")]
        public string property = "Normal_Map";

        [Tooltip("Step the frames in the Scene view too, outside Play mode. This changes the material asset.")]
        public bool animateInEditMode = true;

        DecalProjector projector;
        Renderer target;
        Material playCopy;
        Material playOriginal;
        int last = -1;

        void OnEnable()
        {
            projector = GetComponent<DecalProjector>();
            target = GetComponent<Renderer>();
            if (Application.isPlaying) MakePlayCopy();
#if UNITY_EDITOR
            UnityEditor.EditorApplication.update -= EditorTick;
            UnityEditor.EditorApplication.update += EditorTick;
#endif
        }

        void OnDisable()
        {
#if UNITY_EDITOR
            UnityEditor.EditorApplication.update -= EditorTick;
#endif
            if (playCopy != null)
            {
                // put the original material back and drop the copy
                if (projector != null && projector.material == playCopy) projector.material = playOriginal;
                if (target != null && target.sharedMaterial == playCopy) target.sharedMaterial = playOriginal;
                Destroy(playCopy);
                playCopy = null;
            }
        }

        void Update()
        {
            if (Application.isPlaying) Tick(Time.time);
        }

        // In Play mode the frames go onto a copy, so the material asset on disk never changes.
        void MakePlayCopy()
        {
            Material source = Resolve();
            if (source == null) return;
            playOriginal = source;
            playCopy = new Material(source) { name = source.name + " (playing)" };
            if (material == null || material == source)
            {
                if (projector != null && projector.material == source) projector.material = playCopy;
                else if (target != null && target.sharedMaterial == source) target.sharedMaterial = playCopy;
            }
        }

        // The material to step: the one set in the Inspector, or the one on this GameObject.
        Material Resolve()
        {
            if (material != null) return material;
            if (projector != null) return projector.material;
            if (target != null) return target.sharedMaterial;
            return null;
        }

        void Tick(float time)
        {
            if (frames == null || frames.Length == 0 || framesPerSecond <= 0f) return;
            Material m = playCopy != null ? playCopy : Resolve();
            if (m == null || !m.HasProperty(property)) return;
            int i = (int)(time * framesPerSecond) % frames.Length;
            if (i == last) return;
            last = i;
            m.SetTexture(property, frames[i]);
        }

#if UNITY_EDITOR
        void EditorTick()
        {
            if (Application.isPlaying || this == null || !animateInEditMode) return;
            Tick((float)UnityEditor.EditorApplication.timeSinceStartup);
            UnityEditor.SceneView.RepaintAll();
            UnityEditor.EditorApplication.QueuePlayerLoopUpdate();
        }
#endif
    }
}
