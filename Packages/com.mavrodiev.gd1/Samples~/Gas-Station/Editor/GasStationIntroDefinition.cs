using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStationIntroDefinition : TutorialDefinition
    {
        public override string Id => "Gas-Station-Intro";
        public override string Title => "Introduction";
        public override string Description => "A night gas station in fog and rain:";
        public override int Order => 0;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("Introduction",
                    Text("A night gas station in fog and rain: a canopy with six fluorescent fixtures over two fuel pumps, a small kiosk with warm windows, a wet concrete forecourt, haze and light shafts. This tutorial builds it in the order the layers of a look depend on each other: first the objects and their materials, then the camera, the night sky, the lights, the reflections, the fog, the rain and the post-processing. Every layer is saved before the next one starts, so each step can be compared with the one before."),
                    Text("Everything is real-time: nothing is baked. Every light, reflection and fog effect updates as soon as a value changes.")),
                NewPage("The Hierarchy by layer",
                    Text("<b>The Hierarchy by layer.</b> In the finished scene, the Hierarchy has one parent per layer, numbered like the sections of this tutorial: <i>1-4 · Objects</i>, <i>6 · Wet Ground</i>, <i>7 · Camera</i>, <i>9 · Lights</i>, <i>10 · Fog</i>, <i>11 · Reflections</i>, <i>12 · Rain</i>, and <i>10-13 · Volume (fog, reflections, post)</i>. Switch a parent off (the checkbox at the top of the Inspector) to see what its layer adds to the frame. Build your own scene with the same parents."),
                    Text("The finished scene is <i>Gas-Station.unity</i>. Open it first, look at it from the camera, then build your own version in a new scene next to it. The scene's assets (materials, textures, the pump prefab, the scripts and shaders) are in the same folder, and every step below uses them.")),
            };
        }
    }
}
