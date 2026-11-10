using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation11Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-11-Reflections-on-the-wet-ground";
        public override string Title => "11 · Reflections on the wet ground";
        public override string Description => "A smooth surface shows what is around it.";
        public override int Order => 12;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("11 · Reflections on the wet ground",
                    Text("A smooth surface shows what is around it. Here three things are reflected: the station, the lights and the haze. The scene uses two kinds of reflection together.")),
                NewPage("11.1 · Screen Space Reflections (SSR)",
                    Text("<b>Screen Space Reflections (SSR)</b> for every surface except the ground. In the Volume, add <b>Screen Space Reflection</b>: <i>Mode</i> switched on (not <i>Disabled</i>), <i>Minimum Smoothness</i> 0.25 (rougher surfaces reflect nothing), <i>Smoothness Fade Start</i> 0.35, <i>Max Ray Length</i> 60, <i>Max Ray Steps</i> 128, <i>Roughness Scale</i> −3 (sharp reflections, stretched into streaks). SSR can only reflect what is on screen: an object outside the frame, or hidden behind another, is missing from the reflection.")),
                NewPage("11.2 · A planar reflection",
                    Text("<b>A planar reflection</b> for the ground. A second camera, mirrored below the ground, renders the scene upside down into a texture, and the wet-ground shader reads it. This reflects the haze, which SSR cannot capture well on a rough, bumpy surface.\n• An empty GameObject <i>Planar Reflection</i> with the <b>Planar Reflection</b> script: <i>Source</i> the Main Camera, <i>Plane Height</i> 0, <i>Resolution Scale</i> 0.5. The script creates its own child <i>Reflection Camera</i>.\n• Its <i>Culling Mask</i> leaves out the <b>Water</b> layer, so the ground does not block the view from below. Its <i>Volume Mask</i> is Water too: it uses only a second Volume, <i>Planar Reflection Volume (fog only)</i>, placed on the Water layer, whose profile has the fog, with the other effects switched off (so the grade is not applied twice).\n• <i>Reflect Sky</i> off: where the mirrored camera sees the sky, it sees black.\n• In the ground material: <i>Planar Reflection Strength</i> 3.5 (already in the material; the slider stops at 2), <i>Distortion by the normal</i> 0.03, <i>Vertical stretch</i> 0.35 (the long vertical streaks of light on wet asphalt). <i>Smoothness seen by SSR</i> 0, so SSR does not reflect on the ground a second time."),
                    Text("<b>Save the scene.</b>")),
            };
        }
    }
}
