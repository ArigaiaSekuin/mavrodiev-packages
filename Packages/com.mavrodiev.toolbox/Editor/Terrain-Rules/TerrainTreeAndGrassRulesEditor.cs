// TerrainTreeAndGrassRulesEditor.cs
// The toolbox, Editor. Namespace Mavrodiev.Toolbox.Editor. Petar's, written 2026-11-06 with an AI assistant.

using UnityEditor;
using UnityEngine;

namespace Mavrodiev.Toolbox.Editor
{
    /// <summary>The buttons, a report of what they did and the ground's height at the top, so they
    /// stay in place when the lists grow. The plain Inspector below them.</summary>
    [CustomEditor(typeof(TerrainTreeAndGrassRules))]
    public class TerrainTreeAndGrassRulesEditor : UnityEditor.Editor
    {
        private string report = "";

        public override void OnInspectorGUI()
        {
            var rules = (TerrainTreeAndGrassRules)target;
            TerrainData data = rules.GetComponent<Terrain>().terrainData;

            if (data == null)
            {
                EditorGUILayout.HelpBox("This Terrain has no Terrain Data. Make a terrain with GameObject > 3D Object > Terrain and add this component to it.", MessageType.Warning);
                return;
            }

            EditorGUILayout.HelpBox("Nothing changes until you press a button. Each button replaces everything of its kind on the terrain, hand-placed copies included. Ctrl+Z undoes it.", MessageType.None);

            using (new EditorGUI.DisabledScope(EditorApplication.isPlaying))
            {
                var trees = new GUIContent("Place Trees", "Replaces all trees and rocks on the terrain with what these rows place. Hand-placed ones go too.");
                if (GUILayout.Button(trees, GUILayout.Height(28)))
                {
                    Undo.RegisterCompleteObjectUndo(data, "Place Terrain Trees");
                    report = rules.PlaceTrees();
                }

                var grass = new GUIContent("Place Grass", "Replaces all grass on the terrain with what these rows place. Hand-painted grass goes too.");
                if (GUILayout.Button(grass, GUILayout.Height(28)))
                {
                    Undo.RegisterCompleteObjectUndo(data, "Place Terrain Grass");
                    report = rules.PlaceGrass();
                }
            }

            EditorGUILayout.HelpBox(report == "" ? "Nothing done yet." : report, MessageType.Info);
            EditorGUILayout.LabelField($"The ground on this terrain goes from {data.bounds.min.y:0.#} to {data.bounds.max.y:0.#} m high.", EditorStyles.miniLabel);
            EditorGUILayout.Space();

            DrawDefaultInspector();
        }
    }
}
