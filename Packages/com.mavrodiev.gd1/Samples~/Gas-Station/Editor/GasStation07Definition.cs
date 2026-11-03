using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation07Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-07-The-camera";
        public override string Title => "7 · The camera";
        public override string Description => "The frame is decided before the lights, because lights are placed for what the camera sees.";
        public override int Order => 8;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("7 · The camera",
                    Text("The frame is decided before the lights, because lights are placed for what the camera sees.")),
                NewPage("7.1 · The frame",
                    Text("<b>The frame.</b> In the Game view, set the resolution to <b>1920 × 1080</b> (16:9).")),
                NewPage("7.2 · Main Camera",
                    Text("<b>Main Camera:</b> position (−0.3, 1.3, −26.5), rotation (−3.7, 0.6, 0): eye height, looking very slightly up. <b>Field of View 40</b> (vertical). Clipping Planes: Near 0.05, Far 300.")),
                NewPage("7.3 · Rendering",
                    Text("<b>Rendering.</b> In the camera's <i>Rendering</i> section: <b>Post Processing</b> on, <b>Anti-aliasing: Temporal Anti-aliasing (TAA)</b>, <b>Dithering</b> on (it hides banding in the dark gradients of the fog).")),
                NewPage("7.4 · The reference overlay (optional)",
                    Text("<b>The reference overlay (optional).</b> The <i>Reference Overlay</i> canvas shows the reference image, semi-transparent, over the Game view, to match the frame. Switch it off when the frame is right.")),
            };
        }
    }
}
