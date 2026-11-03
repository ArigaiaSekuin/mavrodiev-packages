using System.Collections.Generic;
using UnityEngine;

namespace Mavrodiev.Tutorials.Editor
{
    /// <summary>
    /// Done when a colour property of every listed material has all three channels between Min and Max,
    /// in sRGB values from 0 to 255 (as the colour picker shows them).
    /// </summary>
    public class ColourRangeCheck : TutorialCheck
    {
        public Material[] Materials = new Material[0];
        [Tooltip("What to call each material in the status line (\"sphere 2\"); the material's name when empty.")]
        public string[] Labels = new string[0];
        public string Property = "_BaseColor";
        public int Min = 32;
        public int Max = 243;

        bool InRange(float channel)
        {
            int value = Mathf.RoundToInt(channel * 255f);
            return value >= Min && value <= Max;
        }

        public override bool Evaluate(out string status)
        {
            var outside = new List<string>();
            for (int i = 0; i < Materials.Length; i++)
            {
                Material material = Materials[i];
                string label = i < Labels.Length && !string.IsNullOrEmpty(Labels[i]) ? Labels[i] : material != null ? material.name : "(missing material)";
                if (material == null || !material.HasProperty(Property))
                {
                    outside.Add(label);
                    continue;
                }
                Color c = material.GetColor(Property);
                if (!InRange(c.r) || !InRange(c.g) || !InRange(c.b))
                    outside.Add(label);
            }
            status = outside.Count == 0
                ? $"All {Materials.Length} are between {Min} and {Max}."
                : $"Still outside {Min} to {Max}: {string.Join(", ", outside)}.";
            return outside.Count == 0;
        }
    }
}
