// Material From Texture Maps - a folder of PBR texture maps (ambientCG, Poly Haven...) becomes one URP Lit material.
//   1. finds the sets in the folder by their file names (colour, normal, roughness, metal, occlusion, height)
//   2. fixes the import settings: colour sRGB on, normal map as Normal map, every data map sRGB off
//   3. packs metallic (RGB) and smoothness = 1 - roughness (A) into <Set>_MetallicSmoothness.png
//   4. makes M_<Set>.mat (URP Lit) with every map, tiled to the surface's real size (Tiling = 1 / real size, for metre UVs)
// Run on selected Lit materials instead, it converts them: it finds the roughness map next to the Base Map
// (or a roughness map sitting in the Metallic Map slot), packs it and assigns the packed map.
// Install: Assets/_Staging/com.mavrodiev.toolbox/Editor/Material-From-Texture-Maps/MaterialFromTextureMaps.cs
// In the package, the Editor asmdef needs: Unity.RenderPipelines.Universal.Editor, Unity.RenderPipelines.Universal.Runtime,
// Unity.RenderPipelines.Core.Runtime.

using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

namespace Mavrodiev.Toolbox.Editor
{
    public enum MapRole { None, Color, NormalGL, NormalDX, Roughness, Metallic, Occlusion, Height, Opacity, PackedARM }

    public class MaterialFromTextureMaps : EditorWindow
    {
        // the role of a map, from the last word of its file name; longer words first
        static readonly (string word, MapRole role)[] Words =
        {
            ("normal_gl", MapRole.NormalGL), ("normalgl", MapRole.NormalGL), ("nor_gl", MapRole.NormalGL),
            ("normal_dx", MapRole.NormalDX), ("normaldx", MapRole.NormalDX), ("nor_dx", MapRole.NormalDX),
            ("ambientocclusion", MapRole.Occlusion), ("ambient_occlusion", MapRole.Occlusion), ("occlusion", MapRole.Occlusion), ("ao", MapRole.Occlusion),
            ("basecolor", MapRole.Color), ("base_color", MapRole.Color), ("albedo", MapRole.Color), ("diffuse", MapRole.Color),
            ("diff", MapRole.Color), ("colour", MapRole.Color), ("color", MapRole.Color), ("col", MapRole.Color),
            ("roughness", MapRole.Roughness), ("rough", MapRole.Roughness),
            ("metalness", MapRole.Metallic), ("metallic", MapRole.Metallic), ("metal", MapRole.Metallic),
            ("displacement", MapRole.Height), ("height", MapRole.Height), ("disp", MapRole.Height),
            ("opacity", MapRole.Opacity), ("alpha", MapRole.Opacity),
            ("arm", MapRole.PackedARM),
            ("normal", MapRole.NormalGL), ("nor", MapRole.NormalGL), ("nrm", MapRole.NormalGL),
        };

        // resolution and format words left in by the download sites: _1K, -JPG, _2k, _png...
        static readonly Regex Noise = new Regex(@"[_\- ](\d+k|jpg|jpeg|png|exr|tif|tiff)(?=[_\- ]|$)", RegexOptions.IgnoreCase);

        DefaultAsset folder;
        float realSize = 2f;
        bool useHeight;
        DefaultAsset outputFolder;
        string report = "";
        Vector2 scroll;

        [MenuItem("Tools/Mavrodiev/Material From Texture Maps", false, 1000)]
        public static void Open() => GetWindow<MaterialFromTextureMaps>("Material From Texture Maps");

        [MenuItem("Assets/Mavrodiev/Material From Texture Maps", false, 1000)]
        static void OpenOnSelection()
        {
            var window = GetWindow<MaterialFromTextureMaps>("Material From Texture Maps");
            var path = AssetDatabase.GetAssetPath(Selection.activeObject);
            if (!AssetDatabase.IsValidFolder(path)) path = Path.GetDirectoryName(path)?.Replace('\\', '/');
            if (!string.IsNullOrEmpty(path)) window.folder = AssetDatabase.LoadAssetAtPath<DefaultAsset>(path);
        }

        void OnGUI()
        {
            EditorGUILayout.LabelField("Make a material from a folder of maps", EditorStyles.boldLabel);
            folder = (DefaultAsset)EditorGUILayout.ObjectField("Maps folder", folder, typeof(DefaultAsset), false);
            realSize = Mathf.Max(0.01f, EditorGUILayout.FloatField("Real size (m)", realSize));
            EditorGUILayout.HelpBox("Tiling = 1 ÷ real size, for surfaces whose UVs are in metres (ProBuilder, a 1 m cube). On other meshes, set Tiling after.", MessageType.None);
            useHeight = EditorGUILayout.Toggle("Use height map", useHeight);
            outputFolder = (DefaultAsset)EditorGUILayout.ObjectField("Save in (empty: with the maps)", outputFolder, typeof(DefaultAsset), false);
            using (new EditorGUI.DisabledScope(folder == null))
                if (GUILayout.Button("Make material")) report = MakeFromFolder(AssetDatabase.GetAssetPath(folder), realSize, useHeight,
                    outputFolder ? AssetDatabase.GetAssetPath(outputFolder) : null);

            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Convert the selected Lit materials", EditorStyles.boldLabel);
            var selected = Selection.GetFiltered<Material>(SelectionMode.Assets);
            using (new EditorGUI.DisabledScope(selected.Length == 0))
                if (GUILayout.Button($"Convert {selected.Length} selected material(s)")) report = Convert(selected);

            EditorGUILayout.Space();
            scroll = EditorGUILayout.BeginScrollView(scroll);
            EditorGUILayout.HelpBox(report == "" ? "Nothing done yet." : report, MessageType.Info);
            EditorGUILayout.EndScrollView();
        }

        // ---------- finding the maps ----------

        public static (string set, MapRole role) Classify(string assetPath)
        {
            var name = Path.GetFileNameWithoutExtension(assetPath);
            if (name.ToLowerInvariant().Contains("metallicsmoothness")) return (null, MapRole.None);   // our own output
            var clean = Noise.Replace(name, "");                                     // the set name keeps its own spelling
            var lower = clean.ToLowerInvariant().Replace('-', '_').Replace(' ', '_');   // matching ignores the separator
            foreach (var (word, role) in Words)
                if (lower.EndsWith("_" + word))
                    return (clean.Substring(0, clean.Length - word.Length - 1), role);
            return (null, MapRole.None);
        }

        static Dictionary<string, Dictionary<MapRole, string>> FindSets(string folderPath)
        {
            var sets = new Dictionary<string, Dictionary<MapRole, string>>();
            foreach (var guid in AssetDatabase.FindAssets("t:Texture2D", new[] { folderPath }))
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                var (set, role) = Classify(path);
                if (role == MapRole.None) continue;
                var key = Path.GetDirectoryName(path).Replace('\\', '/') + "/" + set;   // a set lives in one folder
                if (!sets.TryGetValue(key, out var maps)) sets[key] = maps = new Dictionary<MapRole, string>();
                if (!maps.ContainsKey(role)) maps[role] = path;
            }
            return sets;
        }

        // ---------- 1. import settings ----------

        static void FixImport(string path, MapRole role)
        {
            if (!(AssetImporter.GetAtPath(path) is TextureImporter importer)) return;
            bool changed = false;
            if (role == MapRole.NormalGL || role == MapRole.NormalDX)
            {
                if (importer.textureType != TextureImporterType.NormalMap) { importer.textureType = TextureImporterType.NormalMap; changed = true; }
                bool flip = role == MapRole.NormalDX;   // DirectX normals: green points down; Unity reads OpenGL normals
                if (importer.flipGreenChannel != flip) { importer.flipGreenChannel = flip; changed = true; }
            }
            else
            {
                if (importer.textureType != TextureImporterType.Default) { importer.textureType = TextureImporterType.Default; changed = true; }
                bool srgb = role == MapRole.Color;       // only the colour is shown to the eye; the rest are numbers
                if (importer.sRGBTexture != srgb) { importer.sRGBTexture = srgb; changed = true; }
            }
            if (changed) importer.SaveAndReimport();
        }

        // ---------- 2. packing ----------

        // Reads a texture's pixels through the GPU, so the texture does not need Read/Write enabled.
        // The data maps are sRGB off by then, so the values come through unchanged.
        static Color[] ReadPixels(Texture texture, int width, int height)
        {
            var rt = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
            Graphics.Blit(texture, rt);
            var previous = RenderTexture.active;
            RenderTexture.active = rt;
            var copy = new Texture2D(width, height, TextureFormat.RGBA32, false, true);
            copy.ReadPixels(new Rect(0, 0, width, height), 0, 0);
            copy.Apply();
            RenderTexture.active = previous;
            RenderTexture.ReleaseTemporary(rt);
            var pixels = copy.GetPixels();
            DestroyImmediate(copy);
            return pixels;
        }

        // Metallic in R, G and B (white = bare metal), smoothness = 1 - roughness in A: what URP Lit's Metallic Map reads.
        public static Texture2D Pack(string roughnessPath, string metallicPath, string outputPath)
        {
            var roughness = AssetDatabase.LoadAssetAtPath<Texture2D>(roughnessPath);
            var metallic = metallicPath != null ? AssetDatabase.LoadAssetAtPath<Texture2D>(metallicPath) : null;
            int width = roughness.width, height = roughness.height;
            var rough = ReadPixels(roughness, width, height);
            var metal = metallic != null ? ReadPixels(metallic, width, height) : null;

            var packed = new Texture2D(width, height, TextureFormat.RGBA32, false, true);
            var pixels = new Color[rough.Length];
            for (int i = 0; i < pixels.Length; i++)
            {
                float m = metal != null ? metal[i].r : 0f;
                pixels[i] = new Color(m, m, m, 1f - rough[i].r);
            }
            packed.SetPixels(pixels);
            packed.Apply();
            File.WriteAllBytes(outputPath, packed.EncodeToPNG());
            DestroyImmediate(packed);

            AssetDatabase.ImportAsset(outputPath, ImportAssetOptions.ForceUpdate);
            if (AssetImporter.GetAtPath(outputPath) is TextureImporter importer)
            {
                importer.textureType = TextureImporterType.Default;
                importer.sRGBTexture = false;
                importer.alphaSource = TextureImporterAlphaSource.FromInput;
                importer.alphaIsTransparency = false;
                importer.SaveAndReimport();
            }
            return AssetDatabase.LoadAssetAtPath<Texture2D>(outputPath);
        }

        // ---------- 3. the material ----------

        static void SetKeywords(Material material)
        {
            // URP's own keyword set-up, the same the Lit Inspector runs (verified public in URP 17.6)
            BaseShaderGUI.SetMaterialKeywords(material, UnityEditor.Rendering.Universal.ShaderGUI.LitGUI.SetMaterialKeywords);
        }

        static Texture2D Load(Dictionary<MapRole, string> maps, MapRole role) =>
            maps.TryGetValue(role, out var path) ? AssetDatabase.LoadAssetAtPath<Texture2D>(path) : null;

        // the normal map, OpenGL or DirectX (no ?? on Unity objects: a destroyed object is not null to ??)
        static Texture2D LoadNormal(Dictionary<MapRole, string> maps)
        {
            var normal = Load(maps, MapRole.NormalGL);
            if (normal == null) normal = Load(maps, MapRole.NormalDX);
            return normal;
        }

        public static string MakeFromFolder(string folderPath, float realSize, bool useHeight, string outputFolder)
        {
            var log = new StringBuilder();
            var sets = FindSets(folderPath);
            if (sets.Count == 0) return "No texture maps found (the names need a last word such as _Color, _NormalGL, _Roughness).";
            var lit = Shader.Find("Universal Render Pipeline/Lit");

            foreach (var pair in sets)
            {
                var setFolder = Path.GetDirectoryName(pair.Key).Replace('\\', '/');
                var setName = Path.GetFileName(pair.Key);
                var maps = pair.Value;
                if (maps.ContainsKey(MapRole.PackedARM) && !maps.ContainsKey(MapRole.Roughness))
                    log.AppendLine($"{setName}: a packed ARM map is not used (Lit reads occlusion from green, where ARM keeps roughness). Download the separate maps.");
                if (!maps.ContainsKey(MapRole.Color)) { log.AppendLine($"{setName}: no colour map, skipped."); continue; }

                foreach (var map in maps) FixImport(map.Value, map.Key);

                Texture2D packed = null;
                if (maps.TryGetValue(MapRole.Roughness, out var roughPath))
                {
                    maps.TryGetValue(MapRole.Metallic, out var metalPath);
                    packed = Pack(roughPath, metalPath, $"{setFolder}/{setName}_MetallicSmoothness.png");
                }

                var saveFolder = string.IsNullOrEmpty(outputFolder) ? setFolder : outputFolder;
                var materialPath = $"{saveFolder}/M_{setName}.mat";
                var material = AssetDatabase.LoadAssetAtPath<Material>(materialPath);
                bool isNew = material == null;
                if (isNew) material = new Material(lit);

                material.SetTexture("_BaseMap", Load(maps, MapRole.Color));
                material.SetColor("_BaseColor", Color.white);
                var normal = LoadNormal(maps);
                material.SetTexture("_BumpMap", normal);
                material.SetFloat("_BumpScale", 1f);
                material.SetTexture("_OcclusionMap", Load(maps, MapRole.Occlusion));
                material.SetFloat("_OcclusionStrength", 1f);
                if (packed != null)
                {
                    material.SetTexture("_MetallicGlossMap", packed);
                    material.SetFloat("_SmoothnessTextureChannel", 0f);   // smoothness from the Metallic Map's alpha
                    material.SetFloat("_Smoothness", 1f);                 // the slider scales the map: 1 = the map as it is
                }
                else
                {
                    material.SetFloat("_Metallic", 0f);
                    material.SetFloat("_Smoothness", 0.5f);
                    log.AppendLine($"{setName}: no roughness map, Smoothness left at 0.5: set it by eye.");
                }
                var height = useHeight ? Load(maps, MapRole.Height) : null;
                material.SetTexture("_ParallaxMap", height);
                if (height != null) material.SetFloat("_Parallax", 0.02f);
                material.SetTextureScale("_BaseMap", Vector2.one / realSize);   // Lit uses the Base Map's tiling for every map
                material.SetTextureOffset("_BaseMap", Vector2.zero);
                SetKeywords(material);

                if (isNew) AssetDatabase.CreateAsset(material, materialPath);
                else EditorUtility.SetDirty(material);
                log.AppendLine($"{setName}: {materialPath} ({string.Join(", ", maps.Keys)}), Tiling {1f / realSize:0.###}.");
            }
            AssetDatabase.SaveAssets();
            Debug.Log("Material From Texture Maps\n" + log);
            return log.ToString();
        }

        // ---------- converting existing materials ----------

        public static string Convert(IEnumerable<Material> materials)
        {
            var log = new StringBuilder();
            foreach (var material in materials)
            {
                var shaderName = material.shader != null ? material.shader.name : "";
                if (shaderName != "Universal Render Pipeline/Lit" && shaderName != "Universal Render Pipeline/Complex Lit")
                {
                    log.AppendLine($"{material.name}: not a URP Lit material ({shaderName}), skipped. Convert it to URP first.");
                    continue;
                }
                var baseMap = material.GetTexture("_BaseMap");
                if (baseMap == null) { log.AppendLine($"{material.name}: no Base Map, skipped."); continue; }

                var basePath = AssetDatabase.GetAssetPath(baseMap);
                var (setName, _) = Classify(basePath);
                var setFolder = Path.GetDirectoryName(basePath).Replace('\\', '/');
                var sets = FindSets(setFolder);
                sets.TryGetValue(setFolder + "/" + setName, out var maps);
                if (maps == null) maps = new Dictionary<MapRole, string>();

                // a roughness map placed in the Metallic Map slot (it reads as reversed smoothness)
                var inSlot = material.GetTexture("_MetallicGlossMap");
                bool fromSlot = false;
                if (inSlot != null && Classify(AssetDatabase.GetAssetPath(inSlot)).role == MapRole.Roughness)
                {
                    maps[MapRole.Roughness] = AssetDatabase.GetAssetPath(inSlot);
                    fromSlot = true;
                }

                if (!maps.TryGetValue(MapRole.Roughness, out var roughPath))
                {
                    log.AppendLine($"{material.name}: no roughness map found next to its Base Map, nothing to convert.");
                    continue;
                }
                foreach (var map in maps) FixImport(map.Value, map.Key);
                maps.TryGetValue(MapRole.Metallic, out var metalPath);
                var packedName = string.IsNullOrEmpty(setName) ? material.name : setName;
                var packedPath = $"{setFolder}/{packedName}_MetallicSmoothness.png";
                // the set is already packed (a library set, or a second material on the same maps): use that map
                var packed = fromSlot ? null : AssetDatabase.LoadAssetAtPath<Texture2D>(packedPath);
                if (packed == null) packed = Pack(roughPath, metalPath, packedPath);

                material.SetTexture("_MetallicGlossMap", packed);
                material.SetFloat("_SmoothnessTextureChannel", 0f);
                material.SetFloat("_Smoothness", 1f);
                if (material.GetTexture("_BumpMap") == null) material.SetTexture("_BumpMap", LoadNormal(maps));
                if (material.GetTexture("_OcclusionMap") == null) material.SetTexture("_OcclusionMap", Load(maps, MapRole.Occlusion));
                SetKeywords(material);
                EditorUtility.SetDirty(material);
                log.AppendLine($"{material.name}: {packedName}_MetallicSmoothness.png (smoothness = 1 - roughness) assigned to the Metallic Map; tiling kept.");
            }
            AssetDatabase.SaveAssets();
            Debug.Log("Material From Texture Maps (convert)\n" + log);
            return log.ToString();
        }
    }
}
