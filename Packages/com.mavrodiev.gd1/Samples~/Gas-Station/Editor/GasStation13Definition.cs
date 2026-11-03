using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation13Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-13-Post-processing";
        public override string Title => "13 · Post-processing";
        public override string Description => "Post-processing works on the finished image, after everything above.";
        public override int Order => 14;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("13 · Post-processing",
                    Text("Post-processing works on the finished image, after everything above. Add these overrides to the same global Volume.")),
                NewPage("13.1 · Tonemapping",
                    Text("<b>Tonemapping:</b> <i>Neutral</i>. It brings the bright values (the tubes, the beams) back into the range the screen can show without changing the colours much.")),
                NewPage("13.2 · Bloom",
                    Text("<b>Bloom:</b> Threshold 0, Intensity 0.9, Scatter 0.9, <i>High Quality Filtering</i> on. Every bright surface glows, the tubes and the windows the most.")),
                NewPage("13.3 · Shadows Midtones Highlights",
                    Text("<b>Shadows Midtones Highlights:</b> Shadows (0.8, 1, 1.03), Midtones (0.88, 1, 1.02). A little red is taken out of the dark and middle tones, which keeps the night teal.")),
                NewPage("13.4 · Split Toning",
                    Text("<b>Split Toning:</b> Shadows (0.38, 0.50, 0.56), Highlights (0.60, 0.53, 0.45), Balance −15: cool shadows, warm highlights.")),
                NewPage("13.5 · Screen Space Lens Flare",
                    Text("<b>Screen Space Lens Flare:</b> Intensity 0.35 (first flare 0.6, secondary 0.3, warped 0.3; streaks 0.5, length 0.4, threshold 0.4). The bright tubes leave the streaks and ghosts of a camera lens.")),
                NewPage("13.6 · Chromatic Aberration",
                    Text("<b>Chromatic Aberration:</b> 0.08. A faint colour fringe toward the edges of the frame, as in a real lens.")),
                NewPage("13.7 · Vignette",
                    Text("<b>Vignette:</b> Intensity 0.3, Smoothness 0.5.")),
                NewPage("13.8 · Film Grain",
                    Text("<b>Film Grain:</b> <i>Type: Medium 3</i>, Intensity 0.2."),
                    Text("<b>Save the scene.</b> Compare your saves from the first to the last: each one shows what its layer adds.")),
            };
        }
    }
}
