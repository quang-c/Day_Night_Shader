using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimeController : MonoBehaviour
{
    [SerializeField] private float degreesPerSec = 0f;
    [SerializeField] private float time;

    [SerializeField] private Gradient ambientColor;
    [SerializeField] private Gradient skyTint;
    [SerializeField] private AnimationCurve horizonFog;

    [Header("Sun")]
    [SerializeField] private Light sun;
    [SerializeField] private Gradient sunColor;
    [SerializeField] private AnimationCurve sunSize;
    [SerializeField] private AnimationCurve sunGlareStrength;

    [Header("Moon")]
    [SerializeField] private Light moon;
    [SerializeField] private AnimationCurve moonSize;

    [Header("Fog")]
    [SerializeField] private Gradient fogColor;
    //[SerializeField] private AnimationCurve fogStartDistance;

    [Header("Stars")]
    [SerializeField] private AnimationCurve starFade;

    [Header("Clouds")]
    [SerializeField] private Gradient cloudColor;

    private void Update()
    {

        // begin timer , multiplied by a degreesPerSec
        time += degreesPerSec * Time.deltaTime;

        // reset timer back to the "beginning of the day"
        if (time >= 360f)
        {
            time -= 360f;
        }
        // rotate the sun
        sun.transform.eulerAngles = new Vector3(time, -90f, 0f);
        // rotate the moon
        moon.transform.eulerAngles = new Vector3(time + 180f, -90f, 0f);

        // value that keeps track of the day/night cycle
        float cycleStage = time / 360f;

        // set values for basic lighting settings
        RenderSettings.ambientLight = ambientColor.Evaluate(cycleStage);
        RenderSettings.fogColor = fogColor.Evaluate(cycleStage);
        //RenderSettings.fogStartDistance = fogStartDistance.Evaluate(cycleStage);

        // set values in the skybox shader
        RenderSettings.skybox.SetFloat("_SunGlareStrength", sunGlareStrength.Evaluate(cycleStage));
        RenderSettings.skybox.SetFloat("_SunSize", sunSize.Evaluate(cycleStage));

        RenderSettings.skybox.SetVector("_MoonPosition", new Vector4(-moon.transform.forward.x, -moon.transform.forward.y, -moon.transform.forward.z, 0));
        //RenderSettings.skybox.SetFloat("_MoonSize", moonSize.Evaluate(cycleStage));

        RenderSettings.skybox.SetFloat("_HorizonFogExponent", horizonFog.Evaluate(cycleStage));
        RenderSettings.skybox.SetColor("_SkyTint", skyTint.Evaluate(cycleStage));
        sun.color = sunColor.Evaluate(cycleStage);

        RenderSettings.skybox.SetFloat("_Brightness", starFade.Evaluate(cycleStage));
        RenderSettings.skybox.SetColor("_CloudColor", cloudColor.Evaluate(cycleStage));
    }
}
