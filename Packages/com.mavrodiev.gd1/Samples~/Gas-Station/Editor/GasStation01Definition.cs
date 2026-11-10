using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation01Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-01-The-ground-and-the-layout";
        public override string Title => "1 · The ground and the layout";
        public override string Description => "All the geometry is made with ProBuilder (GameObject › ProBuilder › Cube).";
        public override int Order => 2;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("1 · The ground and the layout",
                    Text("All the geometry is made with ProBuilder (<i>GameObject › ProBuilder › Cube</i>). Sizes are in metres; one Unity unit is one metre.")),
                NewPage("1.1 · The forecourt",
                    Text("<b>The forecourt.</b> A ProBuilder cube 60 × 0.1 × 60 m, its top at y = 0, named <i>Ground</i> under an empty parent <i>Forecourt</i>. Its UVs are set to world space in metres (<i>Tools › ProBuilder › Editors › Open UV Editor</i>, all faces selected, <i>Special › World Space</i>), so a texture's tiling is the same on every face and size.")),
                NewPage("1.2 · The far ground",
                    Text("<b>The far ground.</b> A large flat plane (400 m) just below the forecourt (y = −0.08), named <i>Far Ground</i>. It fills the horizon behind the fog.")),
                NewPage("1.3 · The station's centre",
                    Text("<b>The station's centre</b> is the world origin. The station (island, canopy, rain) is turned <b>−25°</b> around Y, so its left end comes toward the camera and the canopy reads in depth, not flat on.")),
                NewPage("Empty parents",
                    Text("<b>Empty parents.</b> Make an empty parent <i>1-4 · Objects</i> for all the geometry, and inside it one parent per group, so the Hierarchy stays readable: <i>Forecourt</i>, <i>Island</i>, <i>Canopy</i>, <i>Kiosk</i>, <i>Price Sign</i>, <i>Backdrop</i>.")),
            };
        }
    }
}
