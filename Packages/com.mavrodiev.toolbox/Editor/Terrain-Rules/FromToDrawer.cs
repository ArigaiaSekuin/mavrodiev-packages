// FromToDrawer.cs
// The toolbox, Editor. Namespace Mavrodiev.Toolbox.Editor. Petar's, written 2026-11-06 with an AI assistant; the unit added 2026-11-10.

using UnityEditor;
using UnityEngine;

namespace Mavrodiev.Toolbox.Editor
{
    /// <summary>Draws a [FromTo] Vector2 on one line as: Label  from [ ] to [ ] unit.</summary>
    [CustomPropertyDrawer(typeof(FromToAttribute))]
    public class FromToDrawer : PropertyDrawer
    {
        public override float GetPropertyHeight(SerializedProperty property, GUIContent label) => EditorGUIUtility.singleLineHeight;

        public override void OnGUI(Rect rect, SerializedProperty property, GUIContent label)
        {
            string unit = ((FromToAttribute)attribute).unit;

            EditorGUI.BeginProperty(rect, label, property);
            rect = EditorGUI.PrefixLabel(rect, label);

            int indent = EditorGUI.indentLevel;
            EditorGUI.indentLevel = 0;

            // from [ ] to [ ] unit: the two words and the unit take what they need, the numbers share the rest.
            float fromWidth = 34f, toWidth = 20f, gap = 4f;
            float unitWidth = string.IsNullOrEmpty(unit) ? 0f : 18f;
            float field = Mathf.Max((rect.width - fromWidth - toWidth - unitWidth - 2f * gap) / 2f, 24f);

            var r = new Rect(rect.x, rect.y, fromWidth, rect.height);
            EditorGUI.LabelField(r, "from");
            r.x += fromWidth; r.width = field;

            Vector2 range = property.vector2Value;
            EditorGUI.BeginChangeCheck();
            range.x = EditorGUI.FloatField(r, range.x);
            r.x += field + gap; r.width = toWidth;
            EditorGUI.LabelField(r, "to");
            r.x += toWidth; r.width = field;
            range.y = EditorGUI.FloatField(r, range.y);
            if (EditorGUI.EndChangeCheck()) property.vector2Value = range;

            if (unitWidth > 0f)
            {
                r.x += field + gap; r.width = unitWidth;
                EditorGUI.LabelField(r, unit);
            }

            EditorGUI.indentLevel = indent;
            EditorGUI.EndProperty();
        }
    }
}
