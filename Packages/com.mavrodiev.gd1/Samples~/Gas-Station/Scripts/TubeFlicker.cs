using UnityEngine;

namespace Mavrodiev.GD1.GasStation
{

    // A failing fluorescent tube: mostly on, now and then a burst of stutters (off, dim, on) with the odd long drop-out.
    // Drives the fixture's lights and its own tube material's emission together, in edit mode too.
    [ExecuteAlways]
    public class TubeFlicker : MonoBehaviour
    {
        public Light[] lights;
        public Material tubeMaterial;
        [Tooltip("Emission colour property: _EmissionColor in URP/Lit, _EmissiveColor in HDRP/Lit")] public string emissionProperty = "_EmissionColor";
        [Tooltip("Bursts per minute, on average")] public float burstsPerMinute = 9f;
        public int seed = 7;

        [SerializeField, HideInInspector] float[] baseIntensity;
        [SerializeField, HideInInspector] Color baseEmission;
        [SerializeField, HideInInspector] bool captured;

        System.Random rnd;
        double nextBurst, burstEnd, nextSwitch;
        float level = 1f;

        void OnEnable()
        {
            HookEditor();
            if (!captured && lights != null && tubeMaterial != null)
            {
                baseIntensity = new float[lights.Length];
                for (int i = 0; i < lights.Length; i++) baseIntensity[i] = lights[i].intensity;
                baseEmission = tubeMaterial.GetColor(emissionProperty);
                captured = true;
            }
            rnd = new System.Random(seed);
            nextBurst = Now() + 2.0;
        }

        void OnDisable() { UnhookEditor(); Apply(1f); }

        static double Now() { return Time.realtimeSinceStartupAsDouble; }

        void Update() { if (Application.isPlaying) Tick(); }

        void Tick()
        {
            if (!captured) return;
            double t = Now();
            if (t >= nextBurst)                       // a burst starts
            {
                burstEnd = t + 0.25 + rnd.NextDouble() * 1.2;
                nextBurst = burstEnd + rnd.NextDouble() * 2.0 * 60.0 / Mathf.Max(0.1f, burstsPerMinute);
                nextSwitch = t;
            }
            if (t < burstEnd)
            {
                if (t >= nextSwitch)
                {
                    double r = rnd.NextDouble();
                    level = r < 0.45 ? 0.03f : r < 0.7 ? 0.35f : 1f;    // off, dim glow, on
                    nextSwitch = t + 0.02 + rnd.NextDouble() * (level < 0.1f ? 0.15 : 0.07);
                }
            }
            else level = 1f;
            Apply(level);
        }

        void Apply(float k)
        {
            if (!captured) return;
            if (lights != null)
                for (int i = 0; i < lights.Length && i < baseIntensity.Length; i++)
                    if (lights[i]) lights[i].intensity = baseIntensity[i] * k;
            if (tubeMaterial) tubeMaterial.SetColor(emissionProperty, baseEmission * k);
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
