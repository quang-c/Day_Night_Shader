
// random for noise
float rand(float3 x)
{
    return frac(sin(dot(x, float3(33.5382, 51.3478, 42.432))) * 321.523);
}

// random for stars
float2 random(float2 uv)
{
    return frac(sin(mul(uv, float2x2(3.5382, 5.3478, 4.432, 4.321))) * 32.523);
}

// 3d value noise
float noiseFunc(float3 x)
{
    // integer
    float3 i = floor(x);
    
    // fraction
    float3 f = smoothstep(0.0, 1.0, frac(x));
    
    // this is the easy2read version
    //float n000 = rand(i + float3(0, 0, 0));
    //float n001 = rand(i + float3(0, 0, 1));
    //float n010 = rand(i + float3(0, 1, 0));
    //float n011 = rand(i + float3(0, 1, 1));
    //float n100 = rand(i + float3(1, 0, 0));
    //float n101 = rand(i + float3(1, 0, 1));
    //float n110 = rand(i + float3(1, 1, 0));
    //float n111 = rand(i + float3(1, 1, 1));

    //float n00 = lerp(n000, n001, f.z);
    //float n01 = lerp(n010, n011, f.z);
    //float n10 = lerp(n100, n101, f.z);
    //float n11 = lerp(n110, n111, f.z);

    //float n0 = lerp(n00, n01, f.y);
    //float n1 = lerp(n10, n11, f.y);

    //float n = lerp(n0, n1, f.x);
    
    
    // this is the neat version
    float n = lerp(lerp(lerp(rand(i + float3(0, 0, 0)), rand(i + float3(0, 0, 1)), f.z),
              lerp(rand(i + float3(0, 1, 0)), rand(i + float3(0, 1, 1)), f.z), f.y),
              lerp(lerp(rand(i + float3(1, 0, 0)), rand(i + float3(1, 0, 1)), f.z),
              lerp(rand(i + float3(1, 1, 0)), rand(i + float3(1, 1, 1)), f.z), f.y), f.x);
    
    return n;
}

// layering the noise
float layeredNoise(float3 x, float iterations, float amp, float freq)
{
    float noise = 0.0;
    float maximum = 0.0;
    for (float i = 0.0; i <= iterations; i += 1.0)
    {
        noise += noiseFunc(x * pow(freq, i)) * pow(amp, i);
        maximum += pow(amp, i);
    }

    return noise / maximum;
}
