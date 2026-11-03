using System.Collections.Generic;
using Unity.Tutorials.Editor;
using Unity.Tutorials.Editor.Paragraphs;
using UnityEditor;
using UnityEngine;

namespace Mavrodiev.Tutorials.Editor
{
    /// <summary>
    /// One tutorial, written as C# data. Subclass it in a sample's Editor/ folder; TutorialGenerator
    /// finds every subclass and writes its assets into the sample's Tutorial/ folder.
    /// </summary>
    public abstract class TutorialDefinition
    {
        /// <summary>Divider between sections of one page.</summary>
        public const string LINE = "────────────────────────────────────";

        /// <summary>File name: Tutorial/&lt;Id&gt;.asset, and the predictions file Assets/Predictions/&lt;Id&gt;.md.</summary>
        public abstract string Id { get; }
        /// <summary>The title in the tutorial window and on the contents card.</summary>
        public abstract string Title { get; }
        /// <summary>The text on the contents card.</summary>
        public virtual string Description => "";
        /// <summary>The scene the tutorial opens, as a path inside the sample folder ("Materials-Training.unity"); null: it opens none and stays in the active scene.</summary>
        public virtual string Scene => null;
        /// <summary>The card's place on the sample's contents page.</summary>
        public virtual int Order => 0;
        /// <summary>The sample's contents page; when a sample has several tutorials, the first by Order sets it.</summary>
        public virtual string ContentsTitle => Title;
        public virtual string ContentsSubtitle => "";

        /// <summary>The pages, in order. Build them with the helpers below.</summary>
        public abstract IEnumerable<Page> Pages();

        /// <summary>The sample folder ("Assets/_Samples/playground/Materials"), set by the generator before Pages().</summary>
        public string Folder { get; internal set; }

        /// <summary>Loads an asset by its path inside the sample folder.</summary>
        protected T Load<T>(string pathInSample) where T : Object => AssetDatabase.LoadAssetAtPath<T>($"{Folder}/{pathInSample}");

        // ── building blocks ──────────────────────────────────────────────────

        public class Page
        {
            public string Title;
            public string Camera;   // camera switched to when the page opens, or null
            public Block[] Blocks;

            /// <summary>Switches to this camera (Game view, selection and Scene view) when the page opens.</summary>
            public Page ShowCamera(string cameraName)
            {
                Camera = cameraName;
                return this;
            }
        }

        /// <summary>Makes one paragraph of a page. The generator calls it with the page being built.</summary>
        public delegate ParagraphBase Block(Build build);

        /// <summary>What a Block gets: the tutorial and page being written.</summary>
        public class Build
        {
            public TutorialDefinition Definition;
            public Tutorial Tutorial;
            public TutorialPage Page;

            /// <summary>Stores an object (a check, a criterion) inside the tutorial asset.</summary>
            public T Store<T>(T obj) where T : Object
            {
                if (obj != null && !AssetDatabase.Contains(obj))
                {
                    obj.name = obj.GetType().Name;
                    obj.hideFlags |= HideFlags.HideInHierarchy;
                    AssetDatabase.AddObjectToAsset(obj, Tutorial);
                }
                return obj;
            }
        }

        protected static Page NewPage(string title, params Block[] blocks) => new Page { Title = title, Blocks = blocks };

        /// <summary>A block of text; rich text (&lt;b&gt;, &lt;i&gt;), \n and • work.</summary>
        protected static Block Text(string text) => b =>
        {
            var paragraph = ScriptableObject.CreateInstance<NarrativeParagraph>();
            paragraph.Text = text;
            return paragraph;
        };

        /// <summary>The question and a text box; Save writes the answer to Assets/Predictions/&lt;Id&gt;.md under "## key".</summary>
        protected static Block Predict(string key, string question, bool requireAnswer = false) => b =>
        {
            var paragraph = ScriptableObject.CreateInstance<PredictionParagraph>();
            paragraph.File = b.Definition.Id;
            paragraph.Key = key;
            paragraph.Question = question;
            paragraph.RequireAnswer = requireAnswer;
            paragraph.Page = b.Page;
            return paragraph;
        };

        /// <summary>Shows what the student saved for this key ("Your prediction: …").</summary>
        protected static Block YourPrediction(string key) => b =>
        {
            var paragraph = ScriptableObject.CreateInstance<PredictionParagraph>();
            paragraph.File = b.Definition.Id;
            paragraph.Key = key;
            paragraph.ShowOnly = true;
            return paragraph;
        };

        /// <summary>A Try step: title, steps, and an optional live check. Never blocks Next unless blocking is true.</summary>
        protected static Block Try(string title, string steps, TutorialCheck check = null, bool blocking = false) => b =>
        {
            var paragraph = ScriptableObject.CreateInstance<TryParagraph>();
            paragraph.Title = title;
            paragraph.Text = steps;
            paragraph.Check = b.Store(check);
            paragraph.Blocking = blocking;
            paragraph.Page = b.Page;
            return paragraph;
        };

        /// <summary>
        /// The four pages of one station (Playground-Design § Presentation 2): the model with the camera switch,
        /// Predict, Try, and the answer next to the student's own prediction.
        /// </summary>
        protected static IEnumerable<Page> Station(string key, string title, string camera, string model, string question, Block tryStep, string answer)
        {
            yield return NewPage($"{key} · {title}", Text($"<b>The model:</b> {model}")).ShowCamera(camera);
            yield return NewPage($"{key} · Predict", Predict(key, question));
            yield return NewPage($"{key} · Try", tryStep);
            yield return NewPage($"{key} · Answer", YourPrediction(key), Text($"<b>Answer:</b> {answer}"));
        }
    }
}
