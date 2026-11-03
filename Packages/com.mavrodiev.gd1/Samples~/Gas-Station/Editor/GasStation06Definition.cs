using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation06Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-06-The-wet-ground";
        public override string Title => "6 · The wet ground";
        public override string Description => "The forecourt uses its own shader, Gas-Station/Lit Wet Ground:";
        public override int Order => 7;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("6 · The wet ground",
                    Text("The forecourt uses its own shader, <i>Gas-Station/Lit Wet Ground</i>: a copy of URP's Lit shader with three additions. The material is <i>GS-Concrete-Ground</i>.")),
                NewPage("6.1 · The base",
                    Text("<b>The base.</b> The concrete maps, a dark grey Base Color (71, 71, 71), tiling 0.4 (one tile every 2.5 m), and a strong normal (Normal Map scale 2.4), so the wet surface breaks highlights into streaks.")),
                NewPage("6.2 · The wet map",
                    Text("<b>The wet map.</b> One texture laid over the whole forecourt (<i>Textures/URP/Wet-Map.png</i>) tells the shader where each kind of wetness is: <b>red</b> for puddles (darker and very smooth: smoothness 0.92), <b>green</b> for oil stains (almost black and glossy), <b>blue</b> for where rain falls (outside the canopy). The puddles sit where they will mirror the lights toward the camera: in front of the island and along the lines below the fixtures.")),
                NewPage("6.3 · The ripples",
                    Text("<b>The ripples.</b> Rings on the water where drops land. The shader reads a normal map (<i>Ripple Normal</i>, tile 1.2 m, strength 0.35) only where the wet map is blue. An empty GameObject <i>Ripples</i> carries the <b>Ripple Flipbook</b> script: it steps the material's <i>_RippleMap</i> through the 16 frames in <i>Textures/Ripples/</i> at 18 frames per second, so the rings appear and fade.")),
                NewPage("The Water layer",
                    Text("<b>The Water layer.</b> Put <i>Ground</i> and <i>Far Ground</i> on the built-in <b>Water</b> layer (<i>Inspector › Layer</i>). The planar reflection in § 11 uses this layer.")),
            };
        }
    }
}
