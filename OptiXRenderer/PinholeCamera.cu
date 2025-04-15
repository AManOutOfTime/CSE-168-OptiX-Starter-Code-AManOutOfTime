#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>

#include "Payloads.h"

using namespace optix;


rtBuffer<float3, 2> resultBuffer; // used to store the rendered image result

rtDeclareVariable(rtObject, root, , ); // Optix graph

// launchIndex is 2d uint vector with pixel index curr rendering
// rtLaunchIndex gives users current launch index for pixel working on
rtDeclareVariable(uint2, launchIndex, rtLaunchIndex, ); // a 2d index (x, y)

rtDeclareVariable(int1, frameID, , );

// Camera info 

// TODO:: delcare camera varaibles here
rtDeclareVariable(float, width, , );
rtDeclareVariable(float, height, , );
rtDeclareVariable(optix::float3, eye, , );
rtDeclareVariable(optix::float3, center, , );
rtDeclareVariable(optix::float3, up, , );
rtDeclareVariable(float, fovy, , );
rtDeclareVariable(float, maxdepth, , );

RT_PROGRAM void generateRays()
{
    
    /*
        // DEBUG: passing camera values from host to device
        rtPrintf("Eye: %f %f %f\n", eye.x, eye.y, eye.z);
        rtPrintf("Center: %f %f %f\n", center.x, center.y, center.z);
        rtPrintf("Up: %f %f %f\n", up.x, up.y, up.z);
        rtPrintf("Fovy: %f\n", fovy);
    */

    float3 result = make_float3(0.f);
     
    // TODO: calculate the ray direction (change the following lines)
    float fixed_fovy = fovy * M_PIf / 180.0f;// in degrees to radians
    float2 offset = make_float2(0.5f); // centered
    float2 currPixel = make_float2(launchIndex) + offset;

    // modifiers
    float alpha = 2.0f * ((currPixel.x) / width) - 1.0f;
    float beta = 1.0f - 2.0f * ((currPixel.y) / height);
    float aspect = (float)width / height;
    float u_mod = alpha * aspect * tan(fixed_fovy / 2.0f);
    float v_mod = beta * tan(fixed_fovy / 2.0f);

    float3 w = normalize(eye - center);
    float3 u = normalize(cross(up, w));
    float3 v = cross(u, w);

    float3 origin = eye; 
    float3 dir = normalize(u_mod*u + v_mod*v - w); 
    float epsilon = 0.001f; 


    // TODO: modify the following lines if you need
    // Shoot a ray to compute the color of the current pixel
    // 0 for basic ray, 1 for shadow ray
    Ray ray = make_Ray(origin, dir, 0, epsilon, RT_DEFAULT_MAX);
    Payload payload;
    payload.maxdepth = maxdepth;
    rtTrace(root, ray, payload);

    // Write the result
    resultBuffer[launchIndex] = payload.radiance;
}