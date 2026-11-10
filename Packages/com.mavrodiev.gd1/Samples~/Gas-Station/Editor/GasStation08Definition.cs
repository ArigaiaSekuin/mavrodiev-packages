using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation08Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-08-Night-the-sky-and-the-ambient";
        public override string Title => "8 · Night: the sky and the ambient";
        public override string Description => "Open the Lighting window:";
        public override int Order => 9;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("8 · Night: the sky and the ambient",
                    Text("Open the Lighting window: <i>Window › Rendering › Lighting › Environment</i>.")),
                NewPage("8.1 · Skybox Material",
                    Text("<b>Skybox Material:</b> <i>GS-Procedural-Sky</i> (shader <i>Gas-Station/Procedural Night Sky</i>). It starts from three colours blended by height (top, middle, bottom) in a very dark teal, and adds what the shader computes itself: clouds drifting slowly, lit from below by a warm glow along the horizon (the town), stars that the clouds cover, and a moon with a soft glow. All its colours are typed as small linear numbers, because the sky must be about a hundred times darker than the lights. Try <i>Cover</i>, <i>Drift</i> and the moon's <i>Direction</i>; in the fog, the moon and the horizon glow read most. The simpler <i>GS-Gradient-Sky</i> (the three colours only) is in the same folder.")),
                NewPage("8.2 · Environment Lighting",
                    Text("<b>Environment Lighting:</b> <i>Source: Gradient</i>, with the same three colours as the sky (Sky, Equator, Ground). This is the light every surface receives from all around. At night it is low and coloured, never black.")),
                NewPage("8.3 · Environment Reflections",
                    Text("<b>Environment Reflections:</b> <i>Source: Custom</i>, no cubemap, <i>Intensity Multiplier</i> 0, so the shiny surfaces reflect nothing from the sky. The wet ground will only mirror the station and its haze.")),
                NewPage("8.4 · Sun Source",
                    Text("<b>Sun Source:</b> leave it empty for now; § 10 sets it.")),
                NewPage("8.5 · Lighting Settings",
                    Text("<b>Lighting Settings.</b> The scene's Lighting Settings asset has <i>Baked Global Illumination</i> and <i>Realtime Global Illumination</i> both off. Nothing is baked."),
                    Text("<b>Save the scene.</b>")),
            };
        }
    }
}
