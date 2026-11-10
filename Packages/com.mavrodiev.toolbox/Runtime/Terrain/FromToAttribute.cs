// FromToAttribute.cs
// The toolbox, Runtime. Namespace Mavrodiev.Toolbox. Petar's, written 2026-11-06 with an AI assistant; the unit added 2026-11-10.

using UnityEngine;

namespace Mavrodiev.Toolbox
{
    /// <summary>Put this on a Vector2 that holds a range: the Inspector then shows it as
    /// "from [ ] to [ ] unit" instead of X and Y. The drawing is in Editor/Terrain-Rules/FromToDrawer.cs.</summary>
    public class FromToAttribute : PropertyAttribute
    {
        /// <summary>A short unit written after the two numbers, such as "m" or "°". Empty for none.</summary>
        public readonly string unit;

        public FromToAttribute(string unit = "") { this.unit = unit; }
    }
}
