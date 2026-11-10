// FromToDrawer.cs
// The toolbox, Editor. Namespace Mavrodiev.Toolbox.Editor. Petar's, written 2026-11-06 with an AI assistant.

using UnityEditor;
using UnityEngine;

namespace Mavrodiev.Toolbox.Editor
{
    /// <summary>Draws a [FromTo] Vector2 as two numbers labelled "from" and "to", always on one line.</summary>
    [CustomPropertyDrawer(typeof(FromToAttribute))]
    public class FromToDrawer : PropertyDrawer
    {
        public override float GetPropertyHeight(SerializedProperty property, GUIContent label) => EditorGUIUtility.singleLineHeight;

        public override void OnGUI(Rect rect, SerializedProperty property, GUIContent label)
        {
            EditorGUI.BeginProperty(rect, label, property);
            rect = EditorGUI.PrefixLabel(rect, label);

            int indent = EditorGUI.indentLevel;
            float labelWidth = EditorGUIUtility.labelWidth;
            EditorGUI.indentLevel = 0;
            EditorGUIUtility.labelWidth = 32f;

            Vector2 range = property.vector2Value;
            float half = (rect.width - 4f) / 2f;

            EditorGUI.BeginChangeCheck();
            range.x = EditorGUI.FloatField(new Rect(rect.x, rect.y, half, rect.height), "from", range.x);
            range.y = EditorGUI.FloatField(new Rect(rect.x + half + 4f, rect.y, half, rect.height), "to", range.y);
            if (EditorGUI.EndChangeCheck()) property.vector2Value = range;

            EditorGUIUtility.labelWidth = labelWidth;
            EditorGUI.indentLevel = indent;
            EditorGUI.EndProperty();
        }
    }
}
