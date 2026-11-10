using UnityEngine;

namespace Mavrodiev.GD1.Sunset
{
    // The sky is a material (Skybox/Procedural), not a component, so the Timeline cannot key it.
    // This component holds its values as fields, which the Timeline can key, and writes them into the material.
    // Not here: the Sun Disk mode (None / Simple / High Quality), a switch the Timeline cannot blend.
    // Note: it changes the material asset itself, so give the scene its own copy of the sky material.
    [ExecuteAlways]
    public class SkyboxController : MonoBehaviour
    {
        public Material skybox;
        [Header("Sun")]
        [Range(0f, 1f)] public float sunSize = 0.04f;
        [Range(1f, 10f)] public float sunSizeConvergence = 5f;
        [Header("Sky")]
        [Range(0f, 5f)] public float atmosphereThickness = 1f;
        public Color skyTint = new Color(0.5f, 0.5f, 0.5f);
        public Color groundColor = new Color(0.369f, 0.349f, 0.341f);
        [Range(0f, 8f)] public float exposure = 1.3f;

        void Reset()   // when the component is added: take the scene's sky and its values
        {
            skybox = RenderSettings.skybox;
            if (skybox == null) return;
            sunSize = Get("_SunSize", sunSize); sunSizeConvergence = Get("_SunSizeConvergence", sunSizeConvergence);
            atmosphereThickness = Get("_AtmosphereThickness", atmosphereThickness); exposure = Get("_Exposure", exposure);
            if (skybox.HasProperty("_SkyTint")) skyTint = skybox.GetColor("_SkyTint");
            if (skybox.HasProperty("_GroundColor")) groundColor = skybox.GetColor("_GroundColor");
        }

        float Get(string p, float fallback) => skybox.HasProperty(p) ? skybox.GetFloat(p) : fallback;
        void Set(string p, float v) { if (skybox.HasProperty(p) && skybox.GetFloat(p) != v) skybox.SetFloat(p, v); }
        void Set(string p, Color v) { if (skybox.HasProperty(p) && skybox.GetColor(p) != v) skybox.SetColor(p, v); }

        void Update()
        {
            if (skybox == null) return;
            Set("_SunSize", sunSize); Set("_SunSizeConvergence", sunSizeConvergence);
            Set("_AtmosphereThickness", atmosphereThickness); Set("_SkyTint", skyTint); Set("_GroundColor", groundColor);
            Set("_Exposure", exposure);
        }
    }
}
