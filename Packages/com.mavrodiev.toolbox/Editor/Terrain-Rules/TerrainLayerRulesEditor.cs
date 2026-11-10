// TerrainLayerRulesEditor.cs
// The toolbox, Editor. Namespace Mavrodiev.Toolbox.Editor. Petar's, written 2026-11-06 with an AI assistant.

using UnityEditor;
using UnityEngine;

namespace Mavrodiev.Toolbox.Editor
{
    /// <summary>The button, a report of what it did and the ground's height at the top, so they
    /// stay in place when the list grows. The plain Inspector below them.</summary>
    [CustomEditor(typeof(TerrainLayerRules))]
    public class TerrainLayerRulesEditor : UnityEditor.Editor
    {
        private string report = "";

        public override void OnInspectorGUI()
        {
            var rules = (TerrainLayerRules)target;
            TerrainData data = rules.GetComponent<Terrain>().terrainData;

            if (data == null)
            {
                EditorGUILayout.HelpBox("This Terrain has no Terrain Data. Make a terrain with GameObject > 3D Object > Terrain and add this component to it.", MessageType.Warning);
                return;
            }

            EditorGUILayout.HelpBox("Nothing changes until you press the button. Press it again after changing a row or the ground's shape. It repaints the whole terrain, brush work included. Ctrl+Z undoes it.", MessageType.None);

            using (new EditorGUI.DisabledScope(EditorApplication.isPlaying))
            {
                var button = new GUIContent("Paint Layers", "Repaints the whole terrain from these rows. Brush work on layers is replaced.");
                if (GUILayout.Button(button, GUILayout.Height(28)))
                {
                    // The painted amounts live in textures of their own, so they need their own undo.
                    Undo.RegisterCompleteObjectUndo(data, "Paint Terrain Layers");
                    Undo.RegisterCompleteObjectUndo(data.alphamapTextures, "Paint Terrain Layers");
                    report = rules.PaintLayers();
                }
            }

            EditorGUILayout.HelpBox(report == "" ? "Nothing done yet." : report, MessageType.Info);
            EditorGUILayout.LabelField($"The ground on this terrain goes from {data.bounds.min.y:0.#} to {data.bounds.max.y:0.#} m high.", EditorStyles.miniLabel);
            EditorGUILayout.Space();

            DrawDefaultInspector();
        }
    }
}
