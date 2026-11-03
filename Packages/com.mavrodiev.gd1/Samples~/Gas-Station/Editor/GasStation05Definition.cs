using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation05Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-05-Materials-and-textures";
        public override string Title => "5 · Materials and textures";
        public override string Description => "Every surface uses Universal Render Pipeline/Lit, except the wet ground (§ 6) and the rain (§ 12).";
        public override int Order => 6;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("5 · Materials and textures",
                    Text("Every surface uses <b>Universal Render Pipeline/Lit</b>, except the wet ground (§ 6) and the rain (§ 12). The textures are two sets from Poly Haven (CC0): <i>concrete_floor_worn_001</i> and <i>green_metal_rust</i>. Each set has an albedo map, a normal map, and a map that holds metallic and smoothness (the <i>…-MetalSmooth.png</i> files in <i>Textures/URP/</i>, one per material, with the ambient occlusion in green).")),
                NewPage("5.1 · The concrete materials",
                    Text("<b>The concrete materials.</b> <i>GS-Concrete-Curb</i> (curb, kiosk floor and step), <i>GS-Concrete-Wall</i> (kiosk walls), <i>GS-Concrete-Roof</i> (both roof tops). Base Map: the concrete albedo; Normal Map: the concrete normal; Metallic Map: the material's own MetalSmooth map. Tiling around 0.5 to 0.8, so one tile covers 1.2 to 2 m.")),
                NewPage("5.2 · The metal materials",
                    Text("<b>The metal materials.</b> <i>GS-Metal-Canopy</i> (fascia, soffit, ribs, fixture housings, sign pole), <i>GS-Metal-Column</i>, <i>GS-Metal-Pump</i>, <i>GS-Metal-Green</i> (bin, kiosk door). They use the rusted-metal maps. The canopy and column metals use a neutral grey copy of the albedo (<i>green_metal_rust_albedo_neutral.jpg</i>), tinted by the Base Color, so one texture gives several metals.")),
                NewPage("5.3 · The plain materials",
                    Text("<b>The plain materials</b>, with no maps: <i>GS-Steel</i> (metallic 1, smoothness 0.55: spouts, nozzles, keypads), <i>GS-Rubber</i> (almost black, smoothness 0.35: hoses and grips), <i>GS-Plastic-Sign</i> (pump sign panels), <i>GS-Asphalt-Far</i> (very dark, smoothness 0.6), and the two silhouette materials for the poles and wires.")),
                NewPage("5.4 · The emissive materials",
                    Text("<b>The emissive materials.</b> These surfaces give off light of their own. Tick <b>Emission</b> and set the HDR colour. In the colour picker, <i>Intensity</i> multiplies the colour by 2 to the power of the value: 1 doubles it, 3 multiplies it by eight."),
                    Text("• <b><i>GS-Tube-Glass</i></b> — On: the fluorescent tubes · Emission colour (0–255): 170, 230, 255 · Intensity: 2.9\n• <b><i>GS-Lamp-Glass-Warm</i></b> — On: wall lamp glass, interior ceiling panel · Emission colour (0–255): 255, 217, 162 · Intensity: 2.4\n• <b><i>GS-Sodium-Glass</i></b> — On: street lamp heads · Emission colour (0–255): 255, 195, 127 · Intensity: 2.0\n• <b><i>GS-Glass-Window</i></b> — On: both kiosk windows · Emission colour (0–255): 255, 188, 120 · Intensity: 0.5 · Emission Map: <i>Window-Glow.png</i> (brighter at the top)\n• <b><i>GS-Fridge-Glow</i></b> — On: fridge front · Emission colour (0–255): 224, 249, 255 · Intensity: 0.4\n• <b><i>GS-Price-Sign</i></b> — On: sign face · Emission colour (0–255): 255, 255, 255 · Intensity: −0.6 · Emission Map: <i>Price-Sign.png</i> (the prices)\n• <b><i>GS-Screen</i></b> — On: pump screens and price displays · Emission colour (0–255): 191, 255, 236 · Intensity: −1.1")),
                NewPage("Transparent glass",
                    Text("<b>Transparent glass.</b> The window glass is also <b>Transparent</b> (<i>Surface Type</i>), with an alpha of 0.75 in its Base Color, and it casts no shadows (<i>Mesh Renderer › Lighting › Cast Shadows: Off</i>), so the light from inside passes through.")),
                NewPage("Emission and light",
                    Text("<b>Emission and light.</b> An emissive surface is only bright itself: it does not light anything around it. The light that falls on the canopy and the ground comes from real Light components, placed beside the emissive surfaces in § 9."),
                    Text("<b>Save the scene.</b>")),
            };
        }
    }
}
