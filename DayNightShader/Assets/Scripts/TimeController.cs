using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimeController : MonoBehaviour
{
    [SerializeField] 
    private Light sun;

    // 2 minutes is 1 day
    [SerializeField] 
    private float secondsInFullDay = 120f;

    [Range(0, 1)]
    [SerializeField]
    private float currentTimeOfDay = 0f;
    private float timeMultiplier = 1f;
    private float sunInitialIntensity;

    private void Start()
    {
        sunInitialIntensity = sun.intensity;
    }

    private void Update()
    {
        UpdateSun();

        currentTimeOfDay += (Time.deltaTime / secondsInFullDay) * timeMultiplier;

        if (currentTimeOfDay >= 1)
        {
            // restart day
            currentTimeOfDay = 0f;
        }
    }

    void UpdateSun()
    {
        // -90 sunrise, 170 horizon
        sun.transform.localRotation = Quaternion.Euler((currentTimeOfDay * 360f) - 90, 170, 0);

        float intensityMultiplier = 1f;

        // sunrise - sunset
        if (currentTimeOfDay <= 0.23f || currentTimeOfDay >= 0.75f)
        {
            //TODO: change values in shader
            intensityMultiplier = 0f;
        }
        // sunrise fade
        else if (currentTimeOfDay <= 0.25f)
        {
            //TODO: change values in shader
            intensityMultiplier = Mathf.Clamp01((currentTimeOfDay - 0.23f) * (1 / 0.02f));
        }
        // sunset fade
        else if (currentTimeOfDay >= 0.73f)
        {
            //TODO: change values in shader
            intensityMultiplier = Mathf.Clamp01(1 - ((currentTimeOfDay - 0.73f) * (1 / 0.02f)));
        }

        sun.intensity = sunInitialIntensity * intensityMultiplier;

    }
}
