using System.Collections.Generic;
using System.Linq;
using Mavrodiev.Tutorials.Editor;
using UnityEngine;

namespace Mavrodiev.Playground.TutorialTest
{
    /// <summary>
    /// The test tutorial: station C of the materials training (base colour within limits).
    /// Regenerate with Tutorials › Authoring › Generate Mavrodiev Tutorials.
    /// </summary>
    public class TutorialTestDefinition : TutorialDefinition
    {
        public override string Id => "Tutorial-Test";
        public override string Title => "Station C: Base colour within limits";
        public override string Description => "Predict which spheres are outside the range, then bring them inside it.";
        public override string Scene => "Station-C.unity";
        public override string ContentsTitle => "Playground: Tutorial test";
        public override string ContentsSubtitle => "One station, to test the tutorial pipeline.";

        public override IEnumerable<Page> Pages()
        {
            var check = ScriptableObject.CreateInstance<ColourRangeCheck>();
            check.Materials = Enumerable.Range(1, 4).Select(i => Load<Material>($"Materials/M_Train_Base-Colour-{i}.mat")).ToArray();
            check.Labels = new[] { "sphere 1", "sphere 2", "sphere 3", "sphere 4" };
            check.Min = 32;
            check.Max = 243;

            return Station("C", "Base colour within limits", "Camera - Base colour within limits",
                model: "a real non-metal has a base colour between 32 (man-made black) and 243 (snow), in sRGB values from 0 to 255.",
                question: "which of these four spheres are outside that range? Look at them before opening their materials.",
                tryStep: Try("Bring every sphere inside the range",
                    "1. Select a sphere and look at its material in the <b>Inspector</b>.\n" +
                    "2. Click the <b>Base Map</b> colour. In the colour picker, read the RGB values (0 to 255).\n" +
                    "3. Change each sphere that is outside the range so that all three values are between 32 and 243.",
                    check),
                answer: "sphere 2 and sphere 4 were outside the range.\n" +
                        "• Sphere 2 was 12: darker than man-made black (32).\n" +
                        "• Sphere 4 was 255: brighter than snow (243).\n" +
                        "• Sphere 1 (230) and sphere 3 (128) were inside it.");
        }
    }
}
