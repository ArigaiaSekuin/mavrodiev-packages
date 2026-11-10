using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation10Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-10-The-fog-and-the-light-shafts";
        public override string Title => "10 · The fog and the light shafts";
        public override string Description => "The fog comes from the Volumetric Fog renderer feature (§ 0).";
        public override int Order => 11;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("10 · The fog and the light shafts",
                    Text("The fog comes from the Volumetric Fog renderer feature (§ 0). It is controlled from a Volume, and each light must be added to it one by one.")),
                NewPage("10.1 · The Volume",
                    Text("<b>The Volume.</b> <i>GameObject › Volume › Global Volume</i>, named <i>Gas-Station Volume (global)</i>, with the profile <i>Gas-Station-Volume</i>. Add the override <b>Volumetric Fog</b>: <i>Enabled</i> on; <i>Distance</i> 100; <i>Base Height</i> 0, <i>Maximum Height</i> 16 (the fog thins out with height); <i>Density</i> 1; <i>Attenuation Distance</i> 15 (how far one sees through it); <i>Anisotropy</i> 0; <i>Scattering</i> 1; <i>Main Light</i> and <i>Additional Lights</i> contributions on; <i>Max Steps</i> 128; <i>Blur Iterations</i> 2.")),
                NewPage("10.2 · Render Pass Event: Before Rendering Transparents",
                    Text("<b>Render Pass Event: Before Rendering Transparents.</b> The fog is then drawn before the reflections take their picture of the frame, so the wet ground mirrors the haze too (§ 11).")),
                NewPage("10.3 · Add each light to the fog",
                    Text("<b>Add each light to the fog.</b> A light shows in the fog only with a <b>Volumetric Additional Light</b> component on it. Its <i>Anisotropy</i> is 0.7 on every light, and its <i>Scattering</i> is how much of its light the fog catches:"),
                    Text("• <b>Fog Spot</b> — Scattering: 4.34\n• <b>Ceiling Light</b> — Scattering: 1.24\n• <b>Sign Glow</b> — Scattering: 0.6\n• <b>Lamp Light, Sodium Light</b> — Scattering: 0.5\n• <b>Window Beam</b> — Scattering: 0.48\n• <b>Area Light</b> — Scattering: 0.1\n• <b>Tube Light</b> — Scattering: 0.06")),
                NewPage("10.4 · The fog-only lights",
                    Text("<b>The fog-only lights.</b> The Fog Spots carry most of the haze under the canopy, but they should not light the surfaces a second time. The fog feature ignores <b>Rendering Layers</b>, while surfaces respect them. So the Fog Spots are set to a Rendering Layer that no object uses (<i>Light › Rendering › Rendering Layers</i>; name a spare one in <i>Edit › Project Settings › Tags and Layers › Rendering Layers</i>), and their shadows keep the default layers (<i>Custom Shadow Layers</i> on, <i>Layer: Everything</i>), so the canopy, the columns and the pumps still cut their light into shafts. Their short Range (8 m) ends the bright haze about where the canopy ends.")),
                NewPage("10.5 · The distance fog",
                    Text("<b>The distance fog.</b> Unity's own fog, in the Lighting window (<i>Environment › Other Settings › Fog</i>): on, <i>Mode: Exponential Squared</i>, <i>Density</i> 0.015, colour the sky's middle (very dark teal). It fades every surface with its distance from the camera, independently of the volumetric fog: the backdrop and the far ground fade first. Without the Volumetric Fog package, it is the only fog in the scene.")),
                NewPage("10.6 · The fog's sky light",
                    Text("<b>The fog's sky light.</b> The fog is lit only by lights, never by the sky. A <b>Directional Light</b> pointing straight down, named <i>Fog Ambient (fog only)</i>, on the same spare Rendering Layer, gives the whole fog a faint teal glow: Intensity 0.012, colour 88, 194, 255, no shadows. In the Lighting window, set it as the <b>Sun Source</b>. The fog uses the main light for its general glow."),
                    Text("<b>Save the scene.</b> Compare it with the previous save: the halos around the fixtures, the shafts between the columns and the warm beams out of the kiosk come from this step.")),
            };
        }
    }
}
