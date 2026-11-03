// CameraBreathing.cs
// A slow, small drift of a camera, driven by Perlin noise: the camera "breathes".
// The toolbox, Runtime. Namespace Mavrodiev.Toolbox. The VR check needs the XR module (com.unity.modules.xr).
//
// What it does each frame (Play mode only):
//   1. takes off the offset it added last frame (only if nothing else moved the object since),
//   2. reads six smooth noise values (three for position, three for rotation),
//   3. adds them on top of where the object stands, in the object's own axes.
// So it can sit on a camera that a person or another script also moves.
// It never runs in Edit mode, so it never moves a camera in a saved scene.

using UnityEngine;

namespace Mavrodiev.Toolbox
{
    [AddComponentMenu("Mavrodiev/Camera/Camera Breathing")]
    [DisallowMultipleComponent]
    public class CameraBreathing : MonoBehaviour
    {
        [Tooltip("How far the camera drifts from where it stands, in metres.")]
        [Min(0f)] public float amplitude = 0.02f;

        [Tooltip("How far the camera turns, in degrees.")]
        [Min(0f)] public float rotationAmplitude = 0.4f;

        [Tooltip("How fast the drift changes: about how many slow swings per second.")]
        [Min(0f)] public float speed = 0.2f;

        [Tooltip("A different number gives a different movement. The same number gives the same movement every time.")]
        public int seed = 0;

        [Tooltip("Switch the movement off while a VR headset is active. In VR the head already moves the camera, and an extra drift can make people feel sick.")]
        public bool offInVR = true;

        // What this component added last frame, and the pose it left the object in.
        Vector3 addedPosition;
        Quaternion addedRotation = Quaternion.identity;
        Vector3 leftPosition;
        Quaternion leftRotation;
        bool hasOffset;

        void OnDisable()
        {
            RemoveOffset();
        }

        void LateUpdate()
        {
            RemoveOffset();

            if (offInVR && IsVRActive())
                return;

            float t = Time.time * speed;
            float s = seed * 17.31f;

            Vector3 position = new Vector3(Noise(t, s + 0.0f), Noise(t, s + 3.7f), Noise(t, s + 7.1f)) * amplitude;
            // Less roll than pitch and yaw: a rolling horizon reads as a fault, not as breathing.
            Vector3 angles = new Vector3(Noise(t, s + 11.3f), Noise(t, s + 13.9f), 0.3f * Noise(t, s + 19.7f)) * rotationAmplitude;

            // The position offset is in the object's own axes (right, up, forward), expressed in its parent's space.
            addedPosition = transform.localRotation * position;
            addedRotation = Quaternion.Euler(angles);

            transform.localPosition += addedPosition;
            transform.localRotation = transform.localRotation * addedRotation;

            leftPosition = transform.localPosition;
            leftRotation = transform.localRotation;
            hasOffset = true;
        }

        void RemoveOffset()
        {
            if (!hasOffset)
                return;
            hasOffset = false;

            // If something else set the transform since last frame, its value is the new rest pose: leave it.
            if (transform.localPosition != leftPosition || transform.localRotation != leftRotation)
                return;

            transform.localRotation = transform.localRotation * Quaternion.Inverse(addedRotation);
            transform.localPosition -= addedPosition;
        }

        // Smooth noise between -1 and 1.
        static float Noise(float t, float row)
        {
            return Mathf.Clamp01(Mathf.PerlinNoise(t, row)) * 2f - 1f;
        }

        static bool IsVRActive()
        {
#if ENABLE_VR
            return UnityEngine.XR.XRSettings.isDeviceActive;
#else
            return false;
#endif
        }
    }
}
