using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStationReferencesDefinition : TutorialDefinition
    {
        public override string Id => "Gas-Station-References";
        public override string Title => "References and additional materials";
        public override string Description => "- Unity Manual (Unity 6):";
        public override int Order => 16;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("References and additional materials",
                    Text("- Unity Manual (Unity 6): <i>Universal Render Pipeline › Lighting</i>, <i>Light component</i>, <i>Light cookies</i>, <i>Rendering Layers</i>, <i>Screen Space Reflection</i>, <i>Volumes</i>, <i>Particle System modules</i>. - <i>URP Volumetric Fog</i> by Cristian Qiu: github.com/CristianQiu/Unity-URP-Volumetric-Light. - Poly Haven (CC0): <i>Concrete Floor Worn 001</i>, <i>Green Metal Rust</i>.")),
            };
        }
    }
}
