// PlanarReflection.cs (toolbox, Runtime) - Petar's planar reflection from the Gas-Station (URP-Tests), extended:
// several components per scene (one per source camera), and the reflection camera renders only while its source does.
// The shader side: Shaders/Common/Planar-Reflection.hlsl, used by Shaders/Surfaces/Planar-Floor.shader.

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Mavrodiev.Toolbox
{
    // A planar reflection for a flat floor, in edit mode too. A child camera mirrored below the plane renders the scene,
    // fog included (its own volume: fog only, no grade), into _PlanarReflectionTex, which the floor's shader reads.
    // The camera is a real one (not a flipped view matrix), so its image is the main view flipped vertically; the shader
    // reads it at (u, 1 - v). The floor itself sits on a culling-excluded layer (default: Water), so it doesn't hide
    // the scene from below. Not made for VR: one mirrored camera serves one (mono) source camera.
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public class PlanarReflection : MonoBehaviour
    {
        public Camera source;
        public float planeHeight = 0f;
        [Range(0.25f, 1f)] public float resolutionScale = 0.5f;
        [Tooltip("What the reflection sees: not the floor (Water) or UI")] public LayerMask cullingMask = ~((1 << 4) | (1 << 5));
        [Tooltip("The volumes the reflection uses: its own, fog only")] public LayerMask volumeMask = 1 << 4;
        [Tooltip("Off: the reflection sees black where the sky is, so the floor mirrors only the scene and its haze")] public bool reflectSky = false;

        [SerializeField, HideInInspector] Camera reflection;
        RenderTexture target;
        static readonly int TexId = Shader.PropertyToID("_PlanarReflectionTex");
        static readonly List<PlanarReflection> Active = new List<PlanarReflection>();

        public Camera ReflectionCamera { get { Setup(); return reflection; } }

        bool SourceRenders { get { return source && source.isActiveAndEnabled; } }

        void Awake() { if (reflection && !isActiveAndEnabled) reflection.enabled = false; }

        void OnEnable()
        {
            if (Active.Count == 0)
            {
                RenderPipelineManager.beginCameraRendering += OnBeginCamera;
                RenderPipelineManager.beginContextRendering += OnBeginContext;
            }
            if (!Active.Contains(this)) Active.Add(this);
            if (source) Mirror();
        }

        void OnDisable()
        {
            Active.Remove(this);
            if (Active.Count == 0)
            {
                RenderPipelineManager.beginCameraRendering -= OnBeginCamera;
                RenderPipelineManager.beginContextRendering -= OnBeginContext;
                Shader.SetGlobalTexture(TexId, Texture2D.blackTexture);
            }
            if (reflection) { reflection.targetTexture = null; reflection.enabled = false; }
            if (target) { target.Release(); DestroyImmediate(target); target = null; }
        }

        // The reflection renders only while its source does (the tutorial switches station cameras on and off).
        void LateUpdate()
        {
            if (!reflection && source) Setup();      // a source assigned after the component was enabled
            if (reflection) reflection.enabled = SourceRenders;
        }

        // In edit mode LateUpdate runs only when the scene changes, so the same check also runs before every frame
        // any view renders: ticking a station camera on brings its reflection back without a click elsewhere.
        static void OnBeginContext(ScriptableRenderContext context, List<Camera> cameras)
        {
            for (int i = 0; i < Active.Count; i++)
            {
                var p = Active[i];
                if (!p || !p.reflection) continue;
                bool want = p.isActiveAndEnabled && p.SourceRenders;
                if (p.reflection.enabled == want) continue;
                p.reflection.enabled = want;
#if UNITY_EDITOR
                if (want && !Application.isPlaying) UnityEditor.EditorApplication.QueuePlayerLoopUpdate();   // draw once more, now with the reflection
#endif
            }
        }

        void Setup()
        {
            if (!reflection)
            {
                var t = transform.Find("Reflection Camera");
                var go = t ? t.gameObject : new GameObject("Reflection Camera");
                go.transform.SetParent(transform, false);
                reflection = go.GetComponent<Camera>();
                if (!reflection) reflection = go.AddComponent<Camera>();
            }
            reflection.enabled = isActiveAndEnabled && SourceRenders;   // never on while the component is off
            reflection.cullingMask = cullingMask;
            reflection.clearFlags = reflectSky ? CameraClearFlags.Skybox : CameraClearFlags.SolidColor;
            reflection.backgroundColor = Color.black;
            reflection.allowHDR = true;
            reflection.allowMSAA = false;
            reflection.allowDynamicResolution = false;
            reflection.depth = source ? source.depth - 1 : -2;
            var data = reflection.GetUniversalAdditionalCameraData();
            data.renderPostProcessing = true;          // the fog plugin runs only with post-processing on; the volume holds no grade
            data.antialiasing = AntialiasingMode.None;
            data.volumeLayerMask = volumeMask;
            data.volumeTrigger = null;
            data.renderShadows = true;
            data.requiresDepthOption = CameraOverrideOption.On;
        }

        // For each camera about to render: a reflection camera is mirrored from its source and sees no planar
        // reflection itself; a source camera gets its own reflection; any other camera (the Scene view too) gets black.
        static void OnBeginCamera(ScriptableRenderContext context, Camera cam)
        {
            for (int i = 0; i < Active.Count; i++)
            {
                var p = Active[i];
                if (p && p.reflection && p.reflection == cam)
                {
                    p.Mirror();
                    Shader.SetGlobalTexture(TexId, Texture2D.blackTexture);
                    return;
                }
            }
            for (int i = 0; i < Active.Count; i++)
            {
                var p = Active[i];
                if (p && p.source && p.source == cam && p.target)
                {
                    Shader.SetGlobalTexture(TexId, p.target);
                    return;
                }
            }
            Shader.SetGlobalTexture(TexId, Texture2D.blackTexture);
        }

        // The source camera mirrored in the plane, as a proper camera: forward mirrored, up mirrored and negated.
        void Mirror()
        {
            if (!source) return;
            Setup();
            int w = Mathf.Max(16, Mathf.RoundToInt(source.pixelWidth * resolutionScale));
            int h = Mathf.Max(16, Mathf.RoundToInt(source.pixelHeight * resolutionScale));
            if (!target || target.width != w || target.height != h)
            {
                reflection.targetTexture = null;     // never release the camera's own target
                if (target) { target.Release(); DestroyImmediate(target); }
                target = new RenderTexture(w, h, 24, RenderTextureFormat.ARGBHalf) { name = "Planar Reflection", useMipMap = true, autoGenerateMips = true, hideFlags = HideFlags.DontSave };
                target.Create();
            }
            reflection.targetTexture = target;
            var p = source.transform.position; var f = source.transform.forward; var u = source.transform.up;
            reflection.transform.SetPositionAndRotation(
                new Vector3(p.x, 2f * planeHeight - p.y, p.z),
                Quaternion.LookRotation(new Vector3(f.x, -f.y, f.z), -new Vector3(u.x, -u.y, u.z)));
            reflection.fieldOfView = source.fieldOfView;
            reflection.aspect = source.aspect;
            reflection.nearClipPlane = source.nearClipPlane;
            reflection.farClipPlane = source.farClipPlane;
        }
    }
}
