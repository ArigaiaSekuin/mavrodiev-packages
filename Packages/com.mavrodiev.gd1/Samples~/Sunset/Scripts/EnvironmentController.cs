using UnityEngine;

namespace Mavrodiev.GD1.Sunset
{
    // The fog, the ambient light and the reflections are Lighting settings, not components, so the Timeline cannot key them.
    // This component holds the same values as fields, which the Timeline can key, and writes them into the Lighting settings.
    // Nothing else happens here: what you key is what you get. Works in edit mode too, so scrubbing shows the change.
    // Which values matter depends on the modes set in the Lighting window: fog Start and End only for Linear fog, Density only for
    // Exponential; the three ambient colours only for Gradient ambient (with Color ambient, the Sky colour is the one colour);
    // Ambient Intensity only for Skybox ambient.
    [ExecuteAlways]
    public class EnvironmentController : MonoBehaviour
    {
        [Header("Fog (Lighting › Environment › Other Settings)")]
        public bool fog = true;
        public Color fogColor = new Color(0.13f, 0.07f, 0.05f);
        public float fogDensity = 0.006f;
        public float fogStart = 0f;
        public float fogEnd = 300f;

        [Header("Ambient (Lighting › Environment › Environment Lighting)")]
        public Color ambientSky = new Color(0.10f, 0.065f, 0.045f);
        public Color ambientEquator = new Color(0.15f, 0.085f, 0.045f);
        public Color ambientGround = new Color(0.03f, 0.02f, 0.015f);
        [Range(0f, 8f)] public float ambientIntensity = 1f;

        [Header("Reflections (Lighting › Environment › Environment Reflections)")]
        [Range(0f, 1f)] public float reflectionIntensity = 1f;

        void Reset() { CaptureFromScene(); }   // when the component is added: start from the scene's own values

        public void CaptureFromScene()
        {
            fog = RenderSettings.fog; fogColor = RenderSettings.fogColor; fogDensity = RenderSettings.fogDensity;
            fogStart = RenderSettings.fogStartDistance; fogEnd = RenderSettings.fogEndDistance;
            ambientSky = RenderSettings.ambientSkyColor; ambientEquator = RenderSettings.ambientEquatorColor; ambientGround = RenderSettings.ambientGroundColor;
            ambientIntensity = RenderSettings.ambientIntensity; reflectionIntensity = RenderSettings.reflectionIntensity;
        }

        void Update()
        {
            if (RenderSettings.fog != fog) RenderSettings.fog = fog;
            if (RenderSettings.fogColor != fogColor) RenderSettings.fogColor = fogColor;
            if (RenderSettings.fogDensity != fogDensity) RenderSettings.fogDensity = fogDensity;
            if (RenderSettings.fogStartDistance != fogStart) RenderSettings.fogStartDistance = fogStart;
            if (RenderSettings.fogEndDistance != fogEnd) RenderSettings.fogEndDistance = fogEnd;
            if (RenderSettings.ambientSkyColor != ambientSky) RenderSettings.ambientSkyColor = ambientSky;
            if (RenderSettings.ambientEquatorColor != ambientEquator) RenderSettings.ambientEquatorColor = ambientEquator;
            if (RenderSettings.ambientGroundColor != ambientGround) RenderSettings.ambientGroundColor = ambientGround;
            if (RenderSettings.ambientIntensity != ambientIntensity) RenderSettings.ambientIntensity = ambientIntensity;
            if (RenderSettings.reflectionIntensity != reflectionIntensity) RenderSettings.reflectionIntensity = reflectionIntensity;
        }
    }
}
