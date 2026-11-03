using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation12Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-12-The-rain";
        public override string Title => "12 · The rain";
        public override string Description => "The rain is four Particle Systems (GameObject › Effects › Particle System) under an empty Rain at y = 12, turned −25° like the station.";
        public override int Order => 13;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("12 · The rain",
                    Text("The rain is four <b>Particle Systems</b> (<i>GameObject › Effects › Particle System</i>) under an empty <i>Rain</i> at y = 12, turned −25° like the station. They are four boxes around the canopy, so no drop starts above it and the space under the canopy stays dry.")),
                NewPage("The emitters: values",
                    Text("• <b>Rain Front</b> — Centre (local): (0, 0, −16.95) · Box size (m): 36 × 26.1 · Rate over Time: 11 275\n• <b>Rain Back</b> — Centre (local): (0, 0, 10.95) · Box size (m): 36 × 14.1 · Rate over Time: 6091\n• <b>Rain Left</b> — Centre (local): (−11.4, 0, 0) · Box size (m): 13.2 × 7.8 · Rate over Time: 1236\n• <b>Rain Right</b> — Centre (local): (11.4, 0, 0) · Box size (m): 13.2 × 7.8 · Rate over Time: 1236")),
                NewPage("12.1 · Main module",
                    Text("<b>Main module:</b> Start Lifetime 1.33 s, Start Size 0.02 (2 cm). The drops fall from 12 m at 9 m/s, so they die exactly at the ground.")),
                NewPage("12.2 · Shape",
                    Text("<b>Shape:</b> Box, with the size from the table, flat.")),
                NewPage("12.3 · Velocity over Lifetime",
                    Text("<b>Velocity over Lifetime:</b> (0.5, −9, 0.15): straight down with a slight slant.")),
                NewPage("12.4 · Renderer",
                    Text("<b>Renderer:</b> <i>Render Mode: Stretched Billboard</i>, <i>Velocity Scale</i> 0.06, so each drop is drawn as a streak in the direction it falls. Material <i>GS-Rain-Streak</i>: <i>Universal Render Pipeline/Particles/Lit</i>, Transparent, <i>Blend Mode: Additive</i>, alpha 0.4. Lit particles take the colour of the lights they pass through: the drops shine cyan under the canopy lights and warm near the kiosk.")),
                NewPage("12.5 · The splashes",
                    Text("<b>The splashes.</b> A child Particle System <i>Splash</i>, used as a <b>Sub Emitter</b> of the rain on <i>Death</i>: 1 to 3 splashes per drop, lifetime 0.12 to 0.25 s, size 2 to 4 cm, <i>Shape: Hemisphere</i>, <i>Gravity Modifier</i> 1.5. Material <i>GS-Rain-Splash</i>.")),
                NewPage("In the Editor",
                    Text("<b>In the Editor.</b> The rain moves only while one of its Particle Systems is selected, or in Play mode.")),
            };
        }
    }
}
