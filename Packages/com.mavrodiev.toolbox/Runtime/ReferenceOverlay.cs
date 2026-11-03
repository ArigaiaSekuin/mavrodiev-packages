// ReferenceOverlay.cs (toolbox, Runtime)
// Shows a reference picture, half-transparent, over a camera's view, sized to the camera's frame.
// Used by the prefab Runtime/Reference-Overlay.prefab: a Quad (MeshFilter + MeshRenderer with
// Materials/M_Reference-Overlay.mat, URP Unlit, Transparent, Alpha, Render Face Both) and this component.
// Put the prefab as a CHILD of a Camera. It places itself `distance` metres in front of the camera,
// as tall as the frame (Fit Height) or as wide (Fit Width), keeping the picture's own proportions.
// The frame is read from the camera's projection, so Field of View, a Physical Camera's Lens Shift
// and Gate Fit, and orthographic cameras all line up.
// Only its own camera and the Scene view draw it: the other cameras of the scene never see it.
// Untick the component (or the GameObject) to hide the picture.
// The texture and the opacity are set per object (MaterialPropertyBlock): the material asset stays shared.

using UnityEngine;
using UnityEngine.Rendering;

namespace Mavrodiev.Toolbox
{
    [ExecuteAlways]
    [AddComponentMenu("Mavrodiev/Camera/Reference Overlay")]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class ReferenceOverlay : MonoBehaviour
    {
        public enum Fit
        {
            [Tooltip("As tall as the camera's frame.")] Height,
            [Tooltip("As wide as the camera's frame.")] Width
        }

        [Tooltip("The reference picture to show over the camera's view.")]
        public Texture2D reference;

        [Tooltip("0 = invisible, 1 = fully opaque.")]
        [Range(0f, 1f)] public float opacity = 0.4f;

        [Tooltip("How far in front of the camera the picture sits, in metres. Kept beyond the camera's Near clipping plane.")]
        [Min(0.01f)] public float distance = 0.5f;

        [Tooltip("Height: the picture is as tall as the frame. Width: as wide as the frame.")]
        public Fit fit = Fit.Height;

        static readonly int BaseMapId = Shader.PropertyToID("_BaseMap");
        static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");

        MaterialPropertyBlock block;
        MeshRenderer rend;
        Camera owner;

        void OnEnable()
        {
            rend = GetComponent<MeshRenderer>();
            rend.forceRenderingOff = false;
            RenderPipelineManager.beginCameraRendering += OnBeginCamera;
            Apply();
        }

        void OnDisable()
        {
            RenderPipelineManager.beginCameraRendering -= OnBeginCamera;
            if (rend != null)
                rend.forceRenderingOff = true;   // not saved: unticking the component hides the picture
        }

        void OnValidate()
        {
            aspectOf = null;
            if (isActiveAndEnabled)
                Apply();
        }

        void LateUpdate()
        {
            Apply();
        }

        // Before each camera draws: show the picture to its own camera and the Scene view only, placed for that frame.
        void OnBeginCamera(ScriptableRenderContext context, Camera cam)
        {
            if (rend == null)
                return;
            owner = GetComponentInParent<Camera>(true);
            bool mine = cam == owner;
            bool sceneView = cam.cameraType == CameraType.SceneView || cam.cameraType == CameraType.Preview;
            rend.forceRenderingOff = !(mine || sceneView);
            if (mine)
                Place(cam);
        }

        void Apply()
        {
            owner = GetComponentInParent<Camera>(true);
            if (owner == null)
                return;
            Place(owner);

            if (rend == null)
                rend = GetComponent<MeshRenderer>();
            // only the picture: no shadows, no probes
            if (rend.shadowCastingMode != ShadowCastingMode.Off) rend.shadowCastingMode = ShadowCastingMode.Off;
            if (rend.receiveShadows) rend.receiveShadows = false;
            if (rend.lightProbeUsage != LightProbeUsage.Off) rend.lightProbeUsage = LightProbeUsage.Off;
            if (rend.reflectionProbeUsage != ReflectionProbeUsage.Off) rend.reflectionProbeUsage = ReflectionProbeUsage.Off;

            if (block == null)
                block = new MaterialPropertyBlock();
            rend.GetPropertyBlock(block);
            if (reference != null)
                block.SetTexture(BaseMapId, reference);
            block.SetColor(BaseColorId, new Color(1f, 1f, 1f, opacity));
            rend.SetPropertyBlock(block);
        }

        // The picture's own proportions. In the Editor they are read from the source file, so an import
        // setting that rescales the texture (Non-Power of 2 › ToNearest) does not stretch the picture.
        Texture2D aspectOf;
        float aspect = 1f;

        float PictureAspect()
        {
            if (reference == null)
                return 1f;
            if (aspectOf == reference)
                return aspect;
            aspectOf = reference;
            aspect = reference.height > 0 ? (float)reference.width / reference.height : 1f;
#if UNITY_EDITOR
            var importer = UnityEditor.AssetImporter.GetAtPath(UnityEditor.AssetDatabase.GetAssetPath(reference)) as UnityEditor.TextureImporter;
            if (importer != null)
            {
                importer.GetSourceTextureWidthAndHeight(out int w, out int h);
                if (w > 0 && h > 0)
                    aspect = (float)w / h;
            }
#endif
            return aspect;
        }

        void Place(Camera cam)
        {
            // The frame at depth d, read from the projection matrix: half-size = d / m00 (x), d / m11 (y);
            // the frame's centre moves by m02, m12 (a Physical Camera's Lens Shift, an off-centre projection).
            float d = Mathf.Max(distance, cam.nearClipPlane * 1.05f);
            Matrix4x4 p = cam.projectionMatrix;
            float halfW, halfH, cx, cy;
            if (cam.orthographic)
            {
                halfW = 1f / p.m00; halfH = 1f / p.m11;
                cx = -p.m03 / p.m00; cy = -p.m13 / p.m11;
            }
            else
            {
                halfW = d / p.m00; halfH = d / p.m11;
                cx = d * p.m02 / p.m00; cy = d * p.m12 / p.m11;
            }

            float pictureAspect = PictureAspect();

            float w, h;
            if (fit == Fit.Height) { h = 2f * halfH; w = h * pictureAspect; }
            else                   { w = 2f * halfW; h = w / pictureAspect; }

            // the camera may not be the direct parent: place the quad in the camera's space
            Transform ct = cam.transform;
            Vector3 position = ct.TransformPoint(new Vector3(cx, cy, d));
            Vector3 scale = new Vector3(w, h, 1f);
            Vector3 parentScale = transform.parent != null ? transform.parent.lossyScale : Vector3.one;
            if (parentScale.x != 0f && parentScale.y != 0f)
                scale = new Vector3(w / parentScale.x, h / parentScale.y, 1f);

            // set only what changed, so an Edit-mode scene is not touched for nothing
            if ((transform.position - position).sqrMagnitude > 1e-10f) transform.position = position;
            if (Quaternion.Angle(transform.rotation, ct.rotation) > 1e-3f) transform.rotation = ct.rotation;
            if ((transform.localScale - scale).sqrMagnitude > 1e-10f) transform.localScale = scale;
        }
    }
}
