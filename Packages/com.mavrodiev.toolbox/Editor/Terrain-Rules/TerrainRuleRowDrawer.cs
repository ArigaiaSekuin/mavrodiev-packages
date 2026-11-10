// TerrainRuleRowDrawer.cs
// The toolbox, Editor. Namespace Mavrodiev.Toolbox.Editor. Petar's, written 2026-11-10 with an AI assistant.
// Draws one row of Terrain Layer Rules or Terrain Tree And Grass Rules with short labels, so no label hides behind its numbers.

using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Mavrodiev.Toolbox.Editor
{
    /// <summary>One row of the terrain rule tools: a fold-out titled with the row's number and name,
    /// and inside it each setting under a short label. The field's own tooltip stays on hover.</summary>
    [CustomPropertyDrawer(typeof(TerrainLayerRules.LayerRule))]
    [CustomPropertyDrawer(typeof(TerrainTreeAndGrassRules.TreeRule))]
    [CustomPropertyDrawer(typeof(TerrainTreeAndGrassRules.GrassRule))]
    public class TerrainRuleRowDrawer : PropertyDrawer
    {
        // Field name → the short label shown. A field not listed keeps Unity's own label.
        private static readonly Dictionary<string, string> Labels = new Dictionary<string, string>
        {
            { "name", "Name" },
            { "layer", "Layer" },
            { "prefabs", "Prefabs" },
            { "texture", "Texture" },
            { "prefabInstead", "or a Prefab" },
            { "heightRangeMetres", "Height" },
            { "heightFadeMetres", "Height fade (m)" },
            { "slopeRangeDegrees", "Slope" },
            { "slopeFadeDegrees", "Slope fade (°)" },
            { "edgeNoise", "Wavy edge" },
            { "noiseSizeMetres", "Wave size (m)" },
            { "onlyOnLayer", "Only on layer" },
            { "chancePercent", "Chance (%)" },
            { "metresApart", "Spacing (m)" },
            { "density", "Per m²" },
            { "scaleRange", "Size" },
            { "sinkMetres", "Sink (m)" },
            { "randomRotation", "Random turn" },
            { "seed", "Seed" },
        };

        private const float LabelWidth = 104f;
        private const float Gap = 2f;

        public override float GetPropertyHeight(SerializedProperty property, GUIContent label)
        {
            float height = EditorGUIUtility.singleLineHeight;
            if (!property.isExpanded) return height;

            foreach (SerializedProperty child in Children(property))
                height += Gap + EditorGUI.GetPropertyHeight(child, LabelFor(child), true);
            return height + Gap;
        }

        public override void OnGUI(Rect rect, SerializedProperty property, GUIContent label)
        {
            EditorGUI.BeginProperty(rect, label, property);

            var line = new Rect(rect.x, rect.y, rect.width, EditorGUIUtility.singleLineHeight);
            property.isExpanded = EditorGUI.Foldout(line, property.isExpanded, Title(property, label), true, EditorStyles.foldoutHeader);

            if (property.isExpanded)
            {
                float labelWidth = EditorGUIUtility.labelWidth;
                EditorGUIUtility.labelWidth = LabelWidth;
                EditorGUI.indentLevel++;

                float y = line.yMax + Gap;
                foreach (SerializedProperty child in Children(property))
                {
                    GUIContent childLabel = LabelFor(child);
                    float h = EditorGUI.GetPropertyHeight(child, childLabel, true);
                    EditorGUI.PropertyField(new Rect(rect.x, y, rect.width, h), child, childLabel, true);
                    y += h + Gap;
                }

                EditorGUI.indentLevel--;
                EditorGUIUtility.labelWidth = labelWidth;
            }

            EditorGUI.EndProperty();
        }

        // "1 · Snow": the row's number, then its name, or the layer or first prefab it uses.
        private static string Title(SerializedProperty row, GUIContent label)
        {
            string number = label.text;
            int space = number.LastIndexOf(' ');
            if (space >= 0 && int.TryParse(number.Substring(space + 1), out int index)) number = (index + 1).ToString();

            string name = row.FindPropertyRelative("name")?.stringValue;
            if (string.IsNullOrEmpty(name))
            {
                Object thing = row.FindPropertyRelative("layer")?.objectReferenceValue;
                if (thing == null) thing = row.FindPropertyRelative("texture")?.objectReferenceValue;
                if (thing == null) thing = row.FindPropertyRelative("prefabInstead")?.objectReferenceValue;
                SerializedProperty prefabs = row.FindPropertyRelative("prefabs");
                if (thing == null && prefabs != null && prefabs.arraySize > 0) thing = prefabs.GetArrayElementAtIndex(0).objectReferenceValue;
                name = thing != null ? thing.name : "(empty row)";
            }
            return $"{number} · {name}";
        }

        private static GUIContent LabelFor(SerializedProperty child)
        {
            string text = Labels.TryGetValue(child.name, out string shortLabel) ? shortLabel : child.displayName;
            return new GUIContent(text, child.tooltip);
        }

        // The row's own fields, one level down, in the order they are written.
        private static IEnumerable<SerializedProperty> Children(SerializedProperty row)
        {
            SerializedProperty child = row.Copy();
            SerializedProperty end = row.GetEndProperty();
            if (!child.NextVisible(true)) yield break;
            while (!SerializedProperty.EqualContents(child, end))
            {
                yield return child.Copy();
                if (!child.NextVisible(false)) yield break;
            }
        }
    }
}
