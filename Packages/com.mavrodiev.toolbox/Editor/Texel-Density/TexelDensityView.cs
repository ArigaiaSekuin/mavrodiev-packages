// Texel Density View - shows, on every surface of the open scenes, how many texture pixels cover one metre.
// Tools > Mavrodiev > Texel Density View toggles it. While on, each Mesh Renderer and Skinned Mesh Renderer
// draws with a temporary material (shader "Mavrodiev/Debug/Texel-Density") made from its own material's
// Base Map size and Tiling. Off restores the original materials. It also turns itself off before a scene
// is saved, before Play mode, before a script reload, when a scene is opened and when the editor quits,
// so a scene is never saved with the debug materials.
// Install: Assets/_Staging/com.mavrodiev.toolbox/Editor/Texel-Density/TexelDensityView.cs

using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace Mavrodiev.Toolbox.Editor
{
    [InitializeOnLoad]
    public static class TexelDensityView
    {
        const string MenuPath = "Tools/Mavrodiev/Texel Density View";
        const string TargetMenu = "Tools/Mavrodiev/Texel Density Target/";
        const string TargetKey = "Mavrodiev.Toolbox.TexelDensity.Target";
        const string ShaderName = "Mavrodiev/Debug/Texel-Density";

        static bool on;
        static readonly Dictionary<Renderer, Material[]> originals = new Dictionary<Renderer, Material[]>();
        static readonly Dictionary<Material, Material> debugMaterials = new Dictionary<Material, Material>();

        static float Target
        {
            get => EditorPrefs.GetFloat(TargetKey, 512f);
            set => EditorPrefs.SetFloat(TargetKey, value);
        }

        static TexelDensityView()
        {
            EditorSceneManager.sceneSaving += (scene, path) => TurnOff();
            EditorSceneManager.sceneOpening += (path, mode) => TurnOff();
            EditorApplication.playModeStateChanged += state =>
            {
                if (state == PlayModeStateChange.ExitingEditMode) TurnOff();
            };
            AssemblyReloadEvents.beforeAssemblyReload += TurnOff;
            EditorApplication.quitting += TurnOff;
        }

        [MenuItem(MenuPath, false, 2000)]
        static void Toggle()
        {
            if (on) TurnOff();
            else TurnOn();
        }

        [MenuItem(MenuPath, true)]
        static bool ToggleValidate()
        {
            Menu.SetChecked(MenuPath, on);
            return !EditorApplication.isPlayingOrWillChangePlaymode;
        }

        [MenuItem(TargetMenu + "256 px per m", false, 2001)] static void Target256() => SetTarget(256);
        [MenuItem(TargetMenu + "512 px per m", false, 2002)] static void Target512() => SetTarget(512);
        [MenuItem(TargetMenu + "1024 px per m", false, 2003)] static void Target1024() => SetTarget(1024);

        [MenuItem(TargetMenu + "256 px per m", true)] static bool Target256V() { Menu.SetChecked(TargetMenu + "256 px per m", Mathf.Approximately(Target, 256)); return true; }
        [MenuItem(TargetMenu + "512 px per m", true)] static bool Target512V() { Menu.SetChecked(TargetMenu + "512 px per m", Mathf.Approximately(Target, 512)); return true; }
        [MenuItem(TargetMenu + "1024 px per m", true)] static bool Target1024V() { Menu.SetChecked(TargetMenu + "1024 px per m", Mathf.Approximately(Target, 1024)); return true; }

        static void SetTarget(float value)
        {
            Target = value;
            foreach (var material in debugMaterials.Values)
                if (material != null) material.SetFloat("_Target", value);
            SceneView.RepaintAll();
        }

        static void TurnOn()
        {
            var shader = Shader.Find(ShaderName);
            if (shader == null)
            {
                Debug.LogError($"Texel Density View: the shader \"{ShaderName}\" is missing.");
                return;
            }

            int count = 0;
            var renderers = Object.FindObjectsByType<Renderer>(FindObjectsInactive.Include, FindObjectsSortMode.None);
            foreach (var renderer in renderers)
            {
                if (!(renderer is MeshRenderer) && !(renderer is SkinnedMeshRenderer)) continue;
                if (EditorUtility.IsPersistent(renderer)) continue;                       // a prefab asset, not a scene object
                if ((renderer.hideFlags & HideFlags.HideInHierarchy) != 0) continue;      // editor helpers
                var materials = renderer.sharedMaterials;
                if (materials.Length == 0) continue;
                if (materials.Any(m => m != null && m.shader != null && m.shader.name.StartsWith("TextMeshPro"))) continue;

                originals[renderer] = materials;
                renderer.sharedMaterials = materials.Select(m => DebugFor(m, shader)).ToArray();
                count++;
            }

            on = true;
            SceneView.RepaintAll();
            Debug.Log($"Texel Density View on: {count} renderers. Target {Target} texels per metre (green). Blue: half or less. Red: double or more.");
        }

        static void TurnOff()
        {
            if (!on) return;
            foreach (var pair in originals)
                if (pair.Key != null) pair.Key.sharedMaterials = pair.Value;
            originals.Clear();

            foreach (var material in debugMaterials.Values)
                if (material != null) Object.DestroyImmediate(material);
            debugMaterials.Clear();

            on = false;
            SceneView.RepaintAll();
        }

        static Material DebugFor(Material source, Shader shader)
        {
            if (source == null) return null;
            if (debugMaterials.TryGetValue(source, out var cached)) return cached;

            var material = new Material(shader)
            {
                name = source.name + " (Texel Density)",
                hideFlags = HideFlags.DontSave
            };

            // the texture the surface shows: URP's Base Map, or the classic Main Tex
            string property = source.HasProperty("_BaseMap") ? "_BaseMap" : source.HasProperty("_MainTex") ? "_MainTex" : null;
            Texture texture = property != null ? source.GetTexture(property) : null;
            if (texture != null)
            {
                var scale = source.GetTextureScale(property);
                var offset = source.GetTextureOffset(property);
                material.SetVector("_TexSize", new Vector4(texture.width, texture.height, 0, 0));   // the imported size (after Max Size)
                material.SetVector("_TexST", new Vector4(scale.x, scale.y, offset.x, offset.y));
                material.SetFloat("_HasTexture", 1);
            }
            else
            {
                material.SetFloat("_HasTexture", 0);
            }
            material.SetFloat("_Target", Target);

            debugMaterials[source] = material;
            return material;
        }
    }
}
