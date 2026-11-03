using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation09Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-09-The-lights";
        public override string Title => "9 · The lights";
        public override string Description => "URP's rectangle (area) lights work only with baked lighting, so the fluorescent fixtures are made from spot and point lights.";
        public override int Order => 10;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("9 · The lights",
                    Text("URP's rectangle (area) lights work only with baked lighting, so the fluorescent fixtures are made from <b>spot</b> and <b>point</b> lights. Each fixture gets three lights placed at the fixture: an Area Light and a Tube Light under <i>9 · Lights › Canopy › Fixture n Lights</i>, and a Fog Spot, which belongs to the fog layer (<i>10 · Fog › Fog Spots</i>, § 10). The kiosk's, the sign's and the street lamps' lights have their own parents under <i>9 · Lights</i>. Copy the first fixture's lights to the other five once they look right.")),
                NewPage("The lights: values",
                    Text("• <b>Area Light</b> (×6) — Type: Spot, pointing down, 12 cm under the soffit · Intensity: 5.3 · Range: 30 · Spot angle (outer / inner): 170 / 169 · Colour (0–255): 102, 204, 255 · Shadows: Soft · Notes: Cookie: <i>Lambert-Spot-170</i>\n• <b>Tube Light</b> (×6) — Type: Point, at the tube · Intensity: 0.9 · Range: 25 · Colour (0–255): 102, 204, 255 · Shadows: None · Notes: the soft light all around the fixture, on the soffit\n• <b>Fog Spot</b> (×6) — Type: Spot, pointing down · Intensity: 3.5 · Range: 8 · Spot angle (outer / inner): 170 / 90 · Colour (0–255): 92, 199, 255 · Shadows: Soft · Notes: lights only the fog (§ 10)\n• <b>Ceiling Light</b> — Type: Spot, down, inside the kiosk · Intensity: 6.4 · Range: 25 · Spot angle (outer / inner): 170 / 169 · Colour (0–255): 255, 140, 56 · Shadows: Soft · Notes: Cookie: <i>Lambert-Spot-170</i>\n• <b>Window Beam</b> (×2) — Type: Spot, from inside, out through each window, slightly down · Intensity: 104 · Range: 13 · Spot angle (outer / inner): 30 / 18 · Colour (0–255): 255, 140, 56 · Shadows: Soft · Notes: the warm shafts out of the windows\n• <b>Lamp Light</b> — Type: Spot, from the wall lamp, down and out · Intensity: 1.1 · Range: 18 · Spot angle (outer / inner): 120 / 50 · Colour (0–255): 255, 179, 92 · Shadows: Soft · Notes: Cookie: <i>Lambert-Spot-170</i>\n• <b>Sign Glow</b> — Type: Spot, toward the camera, in front of the sign · Intensity: 0.42 · Range: 12 · Spot angle (outer / inner): 120 · Colour (0–255): 217, 230, 255 · Shadows: None · Notes: the sign's halo\n• <b>Sodium Light</b> (×2) — Type: Spot, down, in each street lamp · Intensity: 3.3 · Range: 25 · Spot angle (outer / inner): 110 · Colour (0–255): 255, 140, 51 · Shadows: None · Notes: far away; only the glow will read")),
                NewPage("Why a cookie on the wide spots",
                    Text("<b>Why a cookie on the wide spots.</b> A Spot light's brightness falls off quickly toward the edge of its cone. A flat panel of light (a fluorescent fixture) instead sends a lot of light sideways. The cookie <i>Textures/URP/Lambert-Spot-170.png</i> (<i>Texture Type: Cookie</i>) makes a 170° spot fade gradually from its centre to its edge, like a panel. With the inner angle almost equal to the outer one (169°), the cookie alone decides the falloff.")),
                NewPage("Why the window beams are so bright",
                    Text("<b>Why the window beams are so bright.</b> Their cone is narrow (30°), so the same amount of light is concentrated into a small area. The kiosk's walls shadow them, so once the fog is on each window sends out its own shaft."),
                    Text("<b>Save the scene.</b> The station is now lit, but the air is still clear.")),
            };
        }
    }
}
