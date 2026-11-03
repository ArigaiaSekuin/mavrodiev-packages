using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation14Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-14-The-flickering-tube-optional";
        public override string Title => "14 · The flickering tube (optional)";
        public override string Description => "Fixture 1, the one nearest the camera, flickers like a failing fluorescent tube.";
        public override int Order => 15;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("14 · The flickering tube (optional)",
                    Text("<i>Fixture 1</i>, the one nearest the camera, flickers like a failing fluorescent tube. The <b>Tube Flicker</b> script on it drives the three lights of the fixture and its own tube material (<i>GS-Tube-Glass-Flicker</i>, a copy of <i>GS-Tube-Glass</i>) together: mostly on, with a burst of short drop-outs every few seconds. <i>Emission Property</i> is <i>_EmissionColor</i>. It runs in the Editor too, so the scene shows as changed while it is open.")),
            };
        }
    }
}
