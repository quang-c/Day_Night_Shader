using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimeController : MonoBehaviour
{


    // 2 minutes is 1 day
    //[SerializeField] 
    //private float secondsInFullDay = 120f;

    //[Range(0, 1)]
    //[SerializeField]
    //private float currentTimeOfDay = 0f;
    //private float timeMultiplier = 1f;
    //private float sunInitialIntensity;


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


    private void Start()
    {
        //sunInitialIntensity = sun.intensity;
    }

    private void Update()
    {
        // UpdateSun();

        //currentTimeOfDay += (Time.deltaTime / secondsInFullDay) * timeMultiplier;

        //if (currentTimeOfDay >= 1)
        //{
        //    // restart day
        //    currentTimeOfDay = 0f;
        //}

        // begin timer , multiplied by a multiplier
        time += degreesPerSec * Time.deltaTime;

        if (time >= 360f)
        {
            time -= 360f;
        }

        // rotate the sun
        sun.transform.eulerAngles = new Vector3(time, -90f, 0f);
        // rotate the moon
        moon.transform.eulerAngles = new Vector3(time + 180f, 90f, 0f);

        // value that keeps track of the day/night cycle
        float cycleStage = time / 360f;

        // set values for basic lighting settings
        RenderSettings.ambientLight = ambientColor.Evaluate(cycleStage);
        RenderSettings.fogColor = fogColor.Evaluate(cycleStage);
        //RenderSettings.fogStartDistance = fogStartDistance.Evaluate(cycleStage);

        // set values in the skybox shader
        RenderSettings.skybox.SetFloat("_SunGlareStrength", sunGlareStrength.Evaluate(cycleStage));
        RenderSettings.skybox.SetFloat("_SunSize", sunSize.Evaluate(cycleStage));

        RenderSettings.skybox.SetVector("_MoonPosition", new Vector4(moon.transform.forward.x, -moon.transform.forward.y, -moon.transform.forward.z, 0));
        RenderSettings.skybox.SetFloat("_MoonSize", moonSize.Evaluate(cycleStage));

        RenderSettings.skybox.SetFloat("_HorizonFogExponent", horizonFog.Evaluate(cycleStage));
        RenderSettings.skybox.SetColor("_SkyTint", skyTint.Evaluate(cycleStage));
        sun.color = sunColor.Evaluate(cycleStage);
    }

    //void UpdateSun()
    //{
    //    // -90 sunrise, 170 horizon
    //    sun.transform.localRotation = Quaternion.Euler((currentTimeOfDay * 360f) - 90, 170, 0);

    //    float intensityMultiplier = 1f;

    //    // sunrise - sunset
    //    if (currentTimeOfDay <= 0.23f || currentTimeOfDay >= 0.75f)
    //    {
    //        //TODO: change values in shader
    //        intensityMultiplier = 0f;
    //    }
    //    // sunrise fade
    //    else if (currentTimeOfDay <= 0.25f)
    //    {
    //        //TODO: change values in shader
    //        intensityMultiplier = Mathf.Clamp01((currentTimeOfDay - 0.23f) * (1 / 0.02f));
    //    }
    //    // sunset fade
    //    else if (currentTimeOfDay >= 0.73f)
    //    {
    //        //TODO: change values in shader
    //        intensityMultiplier = Mathf.Clamp01(1 - ((currentTimeOfDay - 0.73f) * (1 / 0.02f)));
    //    }

    //    sun.intensity = sunInitialIntensity * intensityMultiplier;


    //}
}
