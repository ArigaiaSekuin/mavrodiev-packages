using UnityEngine;

namespace Mavrodiev.Tutorials.Editor
{
    /// <summary>
    /// A check of the scene or its assets, shown live under a Try step (see TryParagraph).
    /// Subclass it once per kind of check; the generator stores each one inside the tutorial asset.
    /// </summary>
    public abstract class TutorialCheck : ScriptableObject
    {
        /// <summary>True when the step is done. Status is one short line for the student, done or not.</summary>
        public abstract bool Evaluate(out string status);
    }
}
