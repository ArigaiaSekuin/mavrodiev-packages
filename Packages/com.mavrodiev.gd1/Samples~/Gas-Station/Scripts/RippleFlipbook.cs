using UnityEngine;

namespace Mavrodiev.GD1.GasStation
{

    // Steps a material's normal map through a set of frames (rain ripples on the wet ground), in edit mode too.
    [ExecuteAlways]
    public class RippleFlipbook : MonoBehaviour
    {
        public Material material;
        public Texture2D[] frames;
        public float framesPerSecond = 20f;
        public string property = "_NormalMap";   // HDRP/Decal and URP's Shader Graphs/Decal both name it _NormalMap

        int last = -1;

        void OnEnable() { HookEditor(); }
        void OnDisable() { UnhookEditor(); }

        void Update() { if (Application.isPlaying) Tick(); }

        void Tick()
        {
            if (material == null || frames == null || frames.Length == 0) return;
            int i = (int)(Time.realtimeSinceStartup * framesPerSecond) % frames.Length;
            if (i == last) return;
            last = i;
            material.SetTexture(property, frames[i]);
        }

    #if UNITY_EDITOR
        void EditorTick() { if (!Application.isPlaying && this != null) { Tick(); UnityEditor.SceneView.RepaintAll(); UnityEditor.EditorApplication.QueuePlayerLoopUpdate(); } }
        void HookEditor() { UnityEditor.EditorApplication.update -= EditorTick; UnityEditor.EditorApplication.update += EditorTick; }
        void UnhookEditor() { UnityEditor.EditorApplication.update -= EditorTick; }
    #else
        void HookEditor() { }
        void UnhookEditor() { }
    #endif
    }
}
