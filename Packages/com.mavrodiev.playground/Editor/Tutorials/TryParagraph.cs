using Unity.Tutorials.Editor;
using Unity.Tutorials.Editor.Paragraphs;
using UnityEngine;
using UnityEngine.UIElements;

namespace Mavrodiev.Tutorials.Editor
{
    /// <summary>
    /// A Try step: a title, the steps, and a status line that a TutorialCheck updates twice a second.
    /// By default it never blocks Next (the student may move on before the step is done);
    /// with Blocking on, Next stays disabled until the check passes.
    /// </summary>
    public class TryParagraph : ParagraphBase
    {
        public string Title = "Try";
        [TextArea(3, 15)] public string Text;
        [Tooltip("Optional. Without a check, the step shows no status line.")]
        public TutorialCheck Check;
        [Tooltip("Next stays disabled until the check passes.")]
        public bool Blocking;
        [Tooltip("The page this paragraph sits on (set by the generator), redrawn when a blocking check changes.")]
        public TutorialPage Page;

        static readonly Color Done = new Color(0.35f, 0.8f, 0.4f);
        static readonly Color NotYet = new Color(0.65f, 0.65f, 0.65f);

        bool m_LastDone;

        public override bool IsCompleted()
        {
            if (!Blocking || Check == null)
                return true;
            return Check.Evaluate(out _);
        }

        public override VisualElement GetDisplayRoot()
        {
            var root = new VisualElement();
            root.style.marginTop = 6;
            root.style.marginBottom = 6;
            root.style.paddingLeft = 8;
            root.style.borderLeftWidth = 3;
            root.style.borderLeftColor = NotYet;

            root.Add(Wrapped($"<b>{Title}</b>"));
            root.Add(Wrapped(Text));
            if (Check == null)
                return root;

            var status = Wrapped("");
            status.style.marginTop = 4;
            root.Add(status);

            void Update()
            {
                bool done = Check.Evaluate(out string text);
                status.text = (done ? "✔ " : "○ ") + text;
                status.style.color = done ? Done : NotYet;
                root.style.borderLeftColor = done ? Done : NotYet;
                bool changed = done != m_LastDone;
                m_LastDone = done;
                if (Blocking && changed && Page != null)
                    Page.RaiseNonMaskingSettingsChanged(); // makes the window redraw, so Next follows the check
            }

            m_LastDone = Check.Evaluate(out _);
            Update();
            root.schedule.Execute(Update).Every(500);
            return root;
        }

        static Label Wrapped(string text)
        {
            var label = new Label(text);
            label.style.whiteSpace = WhiteSpace.Normal;
            return label;
        }
    }
}
