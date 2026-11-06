using UnityEditor;
using UnityEngine;

namespace Mavrodiev.Tutorials.Editor
{
    /// <summary>
    /// Methods a tutorial page calls when it opens (its Showing event). The generator writes one
    /// asset of this type next to each sample's tutorials, because an event needs an object to call.
    /// </summary>
    public class TutorialActions : ScriptableObject
    {
        /// <summary>
        /// Turns on the camera with this name and turns off every other camera, so the Game view shows
        /// the station; selects it and aligns the Scene view to it.
        /// </summary>
        public void ShowCamera(string cameraName)
        {
            Camera target = null;
            foreach (Camera camera in Object.FindObjectsByType<Camera>(FindObjectsInactive.Include, FindObjectsSortMode.None))
            {
                bool on = camera.name == cameraName;
                camera.enabled = on;
                if (on)
                    target = camera;
            }
            if (target == null)
            {
                Debug.LogWarning($"Tutorial: no camera named '{cameraName}' in the open scene.");
                return;
            }
            Selection.activeGameObject = target.gameObject;
            if (SceneView.lastActiveSceneView != null)
                SceneView.lastActiveSceneView.AlignViewToObject(target.transform);
        }
    }
}
