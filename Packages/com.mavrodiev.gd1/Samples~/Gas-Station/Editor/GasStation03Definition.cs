using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation03Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-03-The-canopy";
        public override string Title => "3 · The canopy";
        public override string Description => "The slab.";
        public override int Order => 4;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("3.1 · The slab",
                    Text("<b>The slab.</b> A box 9.4 × 7.6 m seen from below. Its underside (the soffit) is at 4.05 m and its top at 4.45 m. Around it, a fascia 12 cm thick that hangs down to 3.90 m.")),
                NewPage("3.2 · The columns",
                    Text("<b>The columns.</b> Two columns 28 cm square at local x = −1.05 and +1.05, inside the pumps, from the curb to the soffit.")),
                NewPage("3.3 · The ribs",
                    Text("<b>The ribs.</b> Five thin ribs (6 × 5 cm) across the soffit at x = 0, ±1.57 and ±3.13. They divide the soffit into six equal panels and catch light along their edges.")),
                NewPage("3.4 · The fixtures",
                    Text("<b>The fixtures.</b> Six housings 1.30 × 0.06 × 0.24 m, each with two tubes (radius 2.2 cm, length 1.2 m) under it: four along the long sides at (±2.35, ±3.1), two on the short sides at (±3.92, 0), turned 90°. Name them <i>Fixture 1</i> to <i>Fixture 6</i> under <i>Canopy/Light Fixtures</i>. Their lights come in § 9.")),
                NewPage("Several materials on one mesh",
                    Text("<b>Several materials on one mesh.</b> The slab has two materials, one on its top and one on its underside. A mesh with several materials can be skipped by the <b>GPU Resident Drawer</b> (the URP Asset's fast drawing path) when it is built with ProBuilder: add a <b>Disallow GPU Driven Rendering</b> component to such meshes if they disappear in the Game view.")),
            };
        }
    }
}
