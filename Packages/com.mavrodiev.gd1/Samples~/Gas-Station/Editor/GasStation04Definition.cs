using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation04Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-04-The-kiosk-the-sign-and-the-backdrop";
        public override string Title => "4 · The kiosk, the sign and the backdrop";
        public override string Description => "The kiosk stands at (9.2, 0, 4.32), turned 65°, so its front faces the station.";
        public override int Order => 5;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("4.1 · The kiosk",
                    Text("<b>The kiosk</b> stands at (9.2, 0, 4.32), turned <b>65°</b>, so its front faces the station. Its walls are separate boxes around a footprint of 6.4 × 4.6 m, 3 m high and 0.25 m thick, with a roof slab 7.0 × 0.28 × 5.6 m that overhangs the front, a front step 6.8 × 0.14 × 1.4 m.")),
                NewPage("4.2 · Its front",
                    Text("<b>Its front</b>, from left to right: a solid door, a window with one centre mullion (from 0.9 to 2.3 m high), and a night-pay counter window with a small hatch and a steel tray. The front is built from separate boxes, with gaps left for the openings: piers between them, a lintel band above and sills below. The size and position of each piece are in the finished scene, under <i>Kiosk</i>. Thin dark frames go around every opening.")),
                NewPage("4.3 · The interior",
                    Text("<b>The interior</b> is only seen through the glass: a counter, a shelf of goods, a fridge with a glowing front, a ceiling panel. Simple boxes are enough.")),
                NewPage("4.4 · The price sign",
                    Text("<b>The price sign</b> at (−8.8, 0, −7.3), turned −67°: a pole (radius 0.12 m, 5 m tall), a cabinet 1.9 × 2.6 × 0.3 m at 6.1 m height, and a flat face in front of it for the prices.")),
                NewPage("4.5 · The backdrop",
                    Text("<b>The backdrop.</b> Wooden poles every 22 m along a line 26 m behind the station, 10 m tall, with three wires between them. The wires are <b>Line Renderers</b> (width 3.5 cm), each with a few points that sag in the middle. Two street lamps on 8 m posts stand at x = −30 and x = 24. In the fog, only their glow will be seen."),
                    Text("<b>Save the scene.</b> This is the first checkpoint: the geometry, in grey.")),
            };
        }
    }
}
