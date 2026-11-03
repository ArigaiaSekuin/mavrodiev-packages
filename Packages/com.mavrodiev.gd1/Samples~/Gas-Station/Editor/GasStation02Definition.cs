using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation02Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-02-The-island-and-the-pumps";
        public override string Title => "2 · The island and the pumps";
        public override string Description => "The curb.";
        public override int Order => 3;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("2.1 · The curb",
                    Text("<b>The curb.</b> A cube 7.4 × 0.18 × 1.7 m (<i>Curb</i>), and on top of it a thin lip 7.5 × 0.03 × 1.8 m (<i>Curb Lip</i>). The lip sticks out slightly: that small edge catches a highlight and makes the curb read as a solid block.")),
                NewPage("2.2 · The pump",
                    Text("<b>The pump</b> is a prefab (<i>Prefabs/Fuel-Pump.prefab</i>, 1.0 × 2.0 × 0.56 m). It is built once and placed twice: a change to the prefab changes both pumps. Look inside it in Prefab Mode: a plinth, two posts, a lower panel, a meter housing, a top cap, and on each face a screen, a price display, a keypad and a nozzle in its holster. The hose is a separate mesh (<i>Meshes/Pump-Hose.asset</i>).")),
                NewPage("2.3 · Place the pumps",
                    Text("<b>Place the pumps</b> on the island at local x = −2.0 and x = +2.0, standing on the curb.")),
                NewPage("2.4 · The waste bin",
                    Text("<b>The waste bin.</b> A small box 0.42 × 0.62 × 0.34 m with a lid, at the centre of the island.")),
            };
        }
    }
}
