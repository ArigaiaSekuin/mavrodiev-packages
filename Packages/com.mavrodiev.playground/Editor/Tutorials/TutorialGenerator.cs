using System;
using System.Collections.Generic;
using System.Linq;
using Unity.Tutorials.Editor;
using Unity.Tutorials.Editor.Paragraphs;
using UnityEditor;
using UnityEditor.Events;
using UnityEngine;
using UnityEngine.Events;
using Object = UnityEngine.Object;

namespace Mavrodiev.Tutorials.Editor
{
    /// <summary>
    /// Writes the tutorial assets of every TutorialDefinition in the project, into its sample's Tutorial/ folder:
    /// &lt;Id&gt;.asset (the tutorial, with its pages inside), Contents.asset (the sample's contents page) and
    /// Tutorial-Actions.asset (what the pages call). Never edit these by hand: change the definition and regenerate.
    /// The menu shows only where the authoring package is installed (the Workshop), not in students' projects.
    /// </summary>
    public static class TutorialGenerator
    {
        public const string OutputFolder = "Tutorial";

#if MAVRODIEV_TUTORIAL_AUTHORING
        [MenuItem("Tutorials/Authoring/Generate Mavrodiev Tutorials")]
#endif
        static void GenerateFromMenu() => Debug.Log(GenerateAll());

        /// <summary>Regenerates every tutorial; returns one line per tutorial written.</summary>
        public static string GenerateAll()
        {
            var report = new System.Text.StringBuilder();
            var byFolder = new Dictionary<string, List<TutorialDefinition>>();
            foreach (Type type in TypeCache.GetTypesDerivedFrom<TutorialDefinition>().Where(t => !t.IsAbstract))
            {
                string folder = SampleFolderOf(type);
                if (folder == null)
                {
                    report.AppendLine($"Skipped {type.Name}: its script must be in a sample's Editor/ folder, in a file named {type.Name}.cs.");
                    continue;
                }
                var definition = (TutorialDefinition)Activator.CreateInstance(type);
                definition.Folder = folder;
                if (!byFolder.TryGetValue(folder, out var list))
                    byFolder[folder] = list = new List<TutorialDefinition>();
                list.Add(definition);
            }

            foreach (var pair in byFolder)
            {
                string output = $"{pair.Key}/{OutputFolder}";
                if (!AssetDatabase.IsValidFolder(output))
                    AssetDatabase.CreateFolder(pair.Key, OutputFolder);
                var actions = LoadOrCreate<TutorialActions>($"{output}/Tutorial-Actions.asset");
                var ordered = pair.Value.OrderBy(d => d.Order).ToList();
                var tutorials = ordered.Select(d => Write(d, output, actions, report)).ToList();
                WriteContents(ordered, tutorials, output);
            }
            AssetDatabase.SaveAssets();
            return report.Length > 0 ? report.ToString() : "No tutorial definitions found.";
        }

        static Tutorial Write(TutorialDefinition definition, string output, TutorialActions actions, System.Text.StringBuilder report)
        {
            var tutorial = LoadOrCreate<Tutorial>($"{output}/{definition.Id}.asset");
            ClearSubAssets(tutorial);

            tutorial.TutorialTitle = definition.Title;
            if (string.IsNullOrEmpty(definition.Scene))
            {
                tutorial.SceneManagementBehavior = Tutorial.SceneManagementBehaviorType.UseActiveScene;
                tutorial.Scenes = new SceneAsset[0];
            }
            else
            {
                var scene = AssetDatabase.LoadAssetAtPath<SceneAsset>($"{definition.Folder}/{definition.Scene}");
                if (scene == null)
                    report.AppendLine($"  {definition.Id}: scene '{definition.Scene}' not found in {definition.Folder}.");
                tutorial.SceneManagementBehavior = Tutorial.SceneManagementBehaviorType.LoadScenes;
                tutorial.Scenes = new[] { scene };
            }
            // Keep true: with false, Tutorial Framework 6.0.7 throws an ArgumentNullException when the tutorial ends.
            tutorial.ReturnToPreviousScenes = true;
            tutorial.ProgressTrackingEnabled = true;
            if (string.IsNullOrEmpty(tutorial.LessonId))
                tutorial.LessonId = Guid.NewGuid().ToString("N");

            var pages = new List<TutorialPage>();
            foreach (TutorialDefinition.Page def in definition.Pages())
            {
                int index = pages.Count;
                var page = ScriptableObject.CreateInstance<TutorialPage>();
                page.Title = def.Title;
                page.name = $"{index}_{new string(def.Title.Where(c => char.IsLetterOrDigit(c) || c == ' ' || c == '-').ToArray())}";
                AssetDatabase.AddObjectToAsset(page, tutorial);
                var so = new SerializedObject(page);
                so.FindProperty("<IndexInTutorial>k__BackingField").intValue = index;
                so.ApplyModifiedPropertiesWithoutUndo();

                var build = new TutorialDefinition.Build { Definition = definition, Tutorial = tutorial, Page = page };
                foreach (TutorialDefinition.Block block in def.Blocks)
                {
                    ParagraphBase paragraph = block(build);
                    paragraph.name = paragraph.GetType().Name;
                    paragraph.hideFlags |= HideFlags.HideInHierarchy;
                    AssetDatabase.AddObjectToAsset(paragraph, tutorial);
                    page.Paragraphs.Add(paragraph);
                }
                if (!string.IsNullOrEmpty(def.Camera))
                {
                    UnityEventTools.AddStringPersistentListener(page.Showing, actions.ShowCamera, def.Camera);
                    // Added listeners default to Runtime Only, which never fires in the Editor.
                    page.Showing.SetPersistentListenerState(page.Showing.GetPersistentEventCount() - 1, UnityEventCallState.EditorAndRuntime);
                }
                EditorUtility.SetDirty(page);
                pages.Add(page);
            }
            tutorial.PagesCollection.SetItems(pages);
            EditorUtility.SetDirty(tutorial);
            report.AppendLine($"{definition.Id}: {pages.Count} pages → {output}/{definition.Id}.asset");
            return tutorial;
        }

        static void WriteContents(List<TutorialDefinition> definitions, List<Tutorial> tutorials, string output)
        {
            var contents = LoadOrCreate<TutorialContainer>($"{output}/Contents.asset");
            contents.Title = definitions[0].ContentsTitle;
            contents.Subtitle = definitions[0].ContentsSubtitle;
            contents.Sections = definitions.Select((d, i) => new TutorialContainer.Section
            {
                Heading = d.Title,
                Text = d.Description,
                Type = TutorialContainer.SectionType.Tutorial,
                Tutorial = tutorials[i],
            }).ToArray();
            EditorUtility.SetDirty(contents);
        }

        // The sample folder is the parent of the Editor/ folder that holds the definition's script.
        static string SampleFolderOf(Type type)
        {
            foreach (string guid in AssetDatabase.FindAssets($"{type.Name} t:MonoScript", new[] { "Assets" }))
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                var script = AssetDatabase.LoadAssetAtPath<MonoScript>(path);
                if (script == null || script.GetClass() != type)
                    continue;
                string folder = path.Substring(0, path.LastIndexOf('/'));
                return folder.EndsWith("/Editor") ? folder.Substring(0, folder.Length - "/Editor".Length) : null;
            }
            return null;
        }

        // Reuses the asset if it exists, so its ID (and every reference to it) survives regeneration.
        static T LoadOrCreate<T>(string path) where T : ScriptableObject
        {
            var asset = AssetDatabase.LoadAssetAtPath<T>(path);
            if (asset != null)
                return asset;
            asset = ScriptableObject.CreateInstance<T>();
            AssetDatabase.CreateAsset(asset, path);
            return asset;
        }

        static void ClearSubAssets(Object main)
        {
            foreach (Object sub in AssetDatabase.LoadAllAssetsAtPath(AssetDatabase.GetAssetPath(main)))
            {
                if (sub == null || sub == main)
                    continue;
                AssetDatabase.RemoveObjectFromAsset(sub);
                Object.DestroyImmediate(sub, true);
            }
        }
    }
}
