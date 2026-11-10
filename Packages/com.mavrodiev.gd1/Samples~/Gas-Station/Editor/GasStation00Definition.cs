using System.Collections.Generic;
using Mavrodiev.Tutorials.Editor;

namespace Mavrodiev.Playground.GasStation
{
    // Generated from Gas-Station-Tutorial.md (the readable version, next to the scene): one tutorial per section, one page per step.
    public class GasStation00Definition : TutorialDefinition
    {
        public override string Id => "Gas-Station-00-Before-you-start-the-project";
        public override string Title => "0 · Before you start: the project";
        public override string Description => "The scene needs four renderer features and a few settings in the URP Asset.";
        public override int Order => 1;
        public override string ContentsTitle => "Gas Station";
        public override string ContentsSubtitle => "Building the scene layer by layer";

        public override IEnumerable<Page> Pages()
        {
            return new List<Page>
            {
                NewPage("0 · Before you start: the project",
                    Text("The scene needs four renderer features and a few settings in the URP Asset. They are project settings, so they are set once for the whole project.")),
                NewPage("The Renderer",
                    Text("<b>The Renderer</b> (<i>Settings/PC_Renderer</i>), <i>Add Renderer Feature</i>:")),
                NewPage("0.1 · Screen Space Ambient Occlusion",
                    Text("<b>Screen Space Ambient Occlusion</b> — the soft dark where objects meet.")),
                NewPage("0.2 · Decal",
                    Text("<b>Decal</b> — used by other scenes; it does no harm here.")),
                NewPage("0.3 · Screen Space Reflection",
                    Text("<b>Screen Space Reflection</b> — sharp reflections of what is on screen.")),
                NewPage("0.4 · Volumetric Fog",
                    Text("<b>Volumetric Fog</b> — from the <i>URP Volumetric Fog</i> package by Cristian Qiu (included in the project). It makes fog that is lit by real lights and cut by their shadows.")),
                NewPage("The rendering path",
                    Text("<b>The rendering path.</b> In the Renderer, the <i>Rendering Path</i> is <b>Forward+</b>. In Forward, each object is lit by a limited number of additional lights (<i>Per Object Limit</i>, at most 8). Forward+ has no limit per object, and this scene uses 26 lights.")),
                NewPage("The URP Asset",
                    Text("<b>The URP Asset</b> (<i>Settings/PC_RPAsset</i>): <b>HDR</b> on (bright values above 1 are kept, so bloom can find them), <b>Depth Texture</b> and <b>Opaque Texture</b> on (the fog and the reflections read them), <b>Additional Lights: Per Pixel</b> with <b>Cast Shadows</b> on. <b>Use Rendering Layers</b> on, in the Lighting section (the fog-only lights in § 10 need it).")),
                NewPage("The Player settings",
                    Text("<b>The Player settings.</b> In <i>Edit › Project Settings › Player › Other Settings</i>, add <i>URP_SCREEN_SPACE_REFLECTION</i> to <b>Scripting Define Symbols</b> and press <b>Apply</b>. Without this symbol the Screen Space Reflection feature does nothing.")),
            };
        }
    }
}
