// 13 · URP, station 7 (Anti-aliasing): the fallback drift until the toolbox has a camera-noise script (topic 10).
using UnityEngine;

namespace Mavrodiev.Playground.URP
{
    /// <summary>
    /// Moves this object slowly side to side in Play mode, along its own right axis.
    /// Used on Camera - 7 so thin, distant edges move across the pixels.
    /// </summary>
    [AddComponentMenu("Mavrodiev/Playground/URP/Slow Drift")]
    public class SlowDrift : MonoBehaviour
    {
        [Tooltip("How far the object moves to each side, in metres.")]
        [Min(0f)] public float amplitude = 0.6f;

        [Tooltip("Seconds for one full swing, left and back.")]
        [Min(0.1f)] public float period = 8f;

        Vector3 _start;

        void OnEnable()
        {
            _start = transform.localPosition;
        }

        void Update()
        {
            float offset = Mathf.Sin(Time.time * 2f * Mathf.PI / period) * amplitude;
            transform.localPosition = _start + transform.localRotation * Vector3.right * offset;
        }

        void OnDisable()
        {
            transform.localPosition = _start;
        }
    }
}
