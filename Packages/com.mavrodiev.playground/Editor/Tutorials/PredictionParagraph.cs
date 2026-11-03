using System;
using System.IO;
using Unity.Tutorials.Editor;
using Unity.Tutorials.Editor.Paragraphs;
using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;

namespace Mavrodiev.Tutorials.Editor
{
    /// <summary>
    /// A tutorial paragraph with a text box: the student writes a prediction, and Save writes it to
    /// Assets/Predictions/<File>.md, one "## <Key>" section per prediction. With ShowOnly it shows
    /// the saved answer instead (for the page that gives the answer).
    /// </summary>
    public class PredictionParagraph : ParagraphBase
    {
        public const string Folder = "Assets/Predictions";

        [Tooltip("The file under Assets/Predictions/, without .md (one file per tutorial).")]
        public string File;
        [Tooltip("The section in that file (one per prediction).")]
        public string Key;
        [Tooltip("The question, shown above the text box and written above the answer in the file.")]
        public string Question;
        [Tooltip("Next stays disabled until an answer is saved.")]
        public bool RequireAnswer;
        [Tooltip("Show the saved answer, read-only, instead of the text box.")]
        public bool ShowOnly;
        [Tooltip("The page this paragraph sits on (set by the generator), redrawn after Save when RequireAnswer is on.")]
        public TutorialPage Page;

        string Path => $"{Folder}/{File}.md";

        public override bool IsCompleted() => ShowOnly || !RequireAnswer || !string.IsNullOrWhiteSpace(Load());

        public override VisualElement GetDisplayRoot()
        {
            var root = new VisualElement();
            root.style.marginTop = 6;
            root.style.marginBottom = 6;

            if (ShowOnly)
            {
                string saved = Load();
                root.Add(Wrapped("<b>Your prediction:</b> " + (string.IsNullOrWhiteSpace(saved) ? "<i>(none saved)</i>" : saved)));
                return root;
            }

            if (!string.IsNullOrEmpty(Question))
                root.Add(Wrapped($"<b>Predict:</b> {Question}"));
            var field = new TextField { multiline = true, value = Load() };
            field.style.minHeight = 60;
            field.style.whiteSpace = WhiteSpace.Normal;
            var status = Wrapped(string.IsNullOrWhiteSpace(field.value) ? "" : $"Saved in {Path}");
            var save = new Button(() =>
            {
                Save(field.value);
                status.text = $"Saved in {Path}";
                if (RequireAnswer && Page != null)
                    Page.RaiseNonMaskingSettingsChanged(); // makes the window redraw, so Next unlocks
            }) { text = "Save prediction" };

            root.Add(field);
            root.Add(save);
            root.Add(status);
            return root;
        }

        static Label Wrapped(string text)
        {
            var label = new Label(text);
            label.style.whiteSpace = WhiteSpace.Normal;
            return label;
        }

        string Load()
        {
            if (!System.IO.File.Exists(Path))
                return "";
            string[] lines = System.IO.File.ReadAllLines(Path);
            int start = Array.IndexOf(lines, "## " + Key);
            if (start < 0)
                return "";
            var answer = new System.Text.StringBuilder();
            for (int i = start + 2; i < lines.Length && !lines[i].StartsWith("## "); i++)
                answer.AppendLine(lines[i]);
            return answer.ToString().Trim();
        }

        void Save(string answer)
        {
            Directory.CreateDirectory(Folder);
            string section = $"## {Key}\n*{Question}*\n\n{answer.Trim()}\n\n";
            string text = System.IO.File.Exists(Path) ? System.IO.File.ReadAllText(Path).Replace("\r\n", "\n") : $"# Predictions: {File}\n\n";
            int start = text.IndexOf($"## {Key}\n", StringComparison.Ordinal);
            if (start < 0)
                text += section;
            else
            {
                int end = text.IndexOf("\n## ", start + 1, StringComparison.Ordinal);
                text = text.Substring(0, start) + section + (end < 0 ? "" : text.Substring(end + 1));
            }
            System.IO.File.WriteAllText(Path, text);
            AssetDatabase.ImportAsset(Path);
        }
    }
}
