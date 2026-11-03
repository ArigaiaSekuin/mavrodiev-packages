using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Mavrodiev.Toolbox.Editor
{
    /// <summary>
    /// Mesh Health: select one or more objects and read what is wrong with their meshes —
    /// holes (open edges), faces turned inside out, scale not 1, size and pivot off the grid,
    /// missing materials, and the triangle count. It only reads; it never changes the mesh.
    /// </summary>
    public class MeshHealthWindow : EditorWindow
    {
        const float k_Grid = 0.1f;          // size and pivot are "on the grid" in 10 cm steps
        const int k_DenseTriangles = 10000; // above this a single prop counts as dense

        Vector2 m_Scroll;
        readonly Dictionary<MeshFilter, Result> m_Cache = new Dictionary<MeshFilter, Result>();

        [MenuItem("Tools/Mavrodiev/Mesh Health")]
        public static void Open()
        {
            var w = GetWindow<MeshHealthWindow>();
            w.titleContent = new GUIContent("Mesh Health");
            w.Show();
        }

        void OnSelectionChange() { m_Cache.Clear(); Repaint(); }
        void OnFocus() => m_Cache.Clear();

        void OnGUI()
        {
            var targets = Selection.gameObjects;
            if (targets.Length == 0)
            {
                EditorGUILayout.HelpBox("Select an object with a mesh in the Hierarchy.", MessageType.Info);
                return;
            }

            if (GUILayout.Button("Check again")) m_Cache.Clear();
            m_Scroll = EditorGUILayout.BeginScrollView(m_Scroll);
            foreach (var go in targets)
            {
                foreach (var mf in go.GetComponentsInChildren<MeshFilter>())
                    DrawReport(mf, m_Cache);
            }
            EditorGUILayout.EndScrollView();
        }

        static void DrawReport(MeshFilter mf, Dictionary<MeshFilter, Result> cache)
        {
            var mesh = mf.sharedMesh;
            EditorGUILayout.Space(6);
            EditorGUILayout.LabelField(mf.gameObject.name, EditorStyles.boldLabel);
            if (mesh == null)
            {
                EditorGUILayout.HelpBox("The Mesh Filter has no mesh.", MessageType.Error);
                return;
            }
            if (!cache.TryGetValue(mf, out var r)) { r = Check(mf); cache[mf] = r; }
            Line(r.openEdges == 0, r.openEdges == 0 ? "Closed: no holes." : r.openEdges + " open edges: the mesh has holes.");
            Line(r.signedVolume >= 0f, r.signedVolume >= 0f ? "Faces point outward." : "Faces point inward: the mesh is inside out (flipped normals).");
            Line(r.scaleIsOne, r.scaleIsOne ? "Scale is 1, 1, 1." : "Scale is " + Vec(r.scale) + ", not 1. Fix the size in the import settings or the mesh.");
            Line(!r.looksLikeCentimetres, r.looksLikeCentimetres ? "The mesh is " + Vec(r.meshSize) + " m: probably made in centimetres (try Scale Factor 0.01)." : "Mesh size " + Vec(r.meshSize) + " m.");
            Line(r.sizeOnGrid, r.sizeOnGrid ? "Size is in whole 10 cm steps." : "Size is off the 10 cm grid.");
            Line(r.pivotOnGrid, r.pivotOnGrid ? "Pivot sits on a corner, an edge midpoint or the centre of the base." : "Pivot is " + Vec(r.pivotOffset) + " m from the bottom corner: off the grid.");
            Line(r.missingMaterials == 0, r.missingMaterials == 0 ? "Every submesh has a material." : r.missingMaterials + " submesh(es) without a material.");
            Line(r.triangles <= k_DenseTriangles, r.triangles.ToString("N0") + " triangles, " + mesh.vertexCount.ToString("N0") + " vertices.");
        }

        static void Line(bool ok, string text)
        {
            var icon = EditorGUIUtility.IconContent(ok ? "TestPassed" : "console.warnicon.sml");
            EditorGUILayout.LabelField(new GUIContent(" " + text, icon.image), EditorStyles.wordWrappedLabel);
        }

        static string Vec(Vector3 v) => v.x.ToString("0.###") + ", " + v.y.ToString("0.###") + ", " + v.z.ToString("0.###");

        public struct Result
        {
            public int openEdges;
            public float signedVolume;
            public bool scaleIsOne;
            public Vector3 scale;
            public Vector3 meshSize;
            public bool looksLikeCentimetres;
            public bool sizeOnGrid;
            public bool pivotOnGrid;
            public Vector3 pivotOffset;
            public int missingMaterials;
            public int triangles;
        }

        /// <summary>Runs every check on one Mesh Filter (in the Editor every mesh can be read).</summary>
        public static Result Check(MeshFilter mf)
        {
            var mesh = mf.sharedMesh;
            var res = new Result();
            var v = mesh.vertices;
            var t = mesh.triangles;
            res.triangles = t.Length / 3;

            // Holes: weld vertices by position, then count edges used by exactly one triangle.
            var weld = new Dictionary<Vector3Int, int>();
            var id = new int[v.Length];
            for (int i = 0; i < v.Length; i++)
            {
                var k = new Vector3Int(Mathf.RoundToInt(v[i].x * 1000f), Mathf.RoundToInt(v[i].y * 1000f), Mathf.RoundToInt(v[i].z * 1000f));
                if (!weld.TryGetValue(k, out id[i])) { id[i] = weld.Count; weld.Add(k, id[i]); }
            }
            var edges = new Dictionary<long, int>();
            double vol = 0;
            for (int i = 0; i < t.Length; i += 3)
            {
                for (int e = 0; e < 3; e++)
                {
                    int a = id[t[i + e]], b = id[t[i + (e + 1) % 3]];
                    long key = a < b ? ((long)a << 32) | (uint)b : ((long)b << 32) | (uint)a;
                    edges.TryGetValue(key, out int n);
                    edges[key] = n + 1;
                }
                vol += Vector3.Dot(v[t[i]], Vector3.Cross(v[t[i + 1]], v[t[i + 2]])) / 6.0;
            }
            foreach (var n in edges.Values) if (n == 1) res.openEdges++;
            res.signedVolume = (float)vol;

            // Scale and size.
            res.scale = mf.transform.lossyScale;
            res.scaleIsOne = Approx(res.scale.x, 1f) && Approx(res.scale.y, 1f) && Approx(res.scale.z, 1f);
            var b0 = mesh.bounds;
            res.meshSize = b0.size;
            res.looksLikeCentimetres = Mathf.Max(b0.size.x, Mathf.Max(b0.size.y, b0.size.z)) > 30f;
            res.sizeOnGrid = OnGrid(b0.size.x) && OnGrid(b0.size.y) && OnGrid(b0.size.z);

            // Pivot (the mesh's origin) against the bounds: a corner, an edge midpoint or the base centre.
            res.pivotOffset = -b0.min;
            res.pivotOnGrid = PivotOk(b0.min.x, b0.max.x) && Approx(b0.min.y, 0f) && PivotOk(b0.min.z, b0.max.z);

            // Materials.
            var mr = mf.GetComponent<Renderer>();
            if (mr != null)
            {
                var mats = mr.sharedMaterials;
                for (int s = 0; s < mesh.subMeshCount; s++)
                    if (s >= mats.Length || mats[s] == null) res.missingMaterials++;
            }
            return res;
        }

        static bool Approx(float a, float b) => Mathf.Abs(a - b) < 0.001f;
        static bool OnGrid(float x) => Mathf.Abs(x / k_Grid - Mathf.Round(x / k_Grid)) < 0.01f;
        static bool PivotOk(float min, float max) => Approx(min, 0f) || Approx(max, 0f) || Approx(min + max, 0f);
    }
}
