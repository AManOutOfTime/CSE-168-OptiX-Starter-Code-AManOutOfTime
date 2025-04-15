#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>
#include "random.h"

#include "Payloads.h"
#include "Geometries.h"
#include "Light.h"

using namespace optix;

// Declare light buffers
rtBuffer<PointLight> plights;
rtBuffer<DirectionalLight> dlights;

// Declare variables
rtDeclareVariable(Payload, payload, rtPayload, );
rtDeclareVariable(rtObject, root, , );

// Declare attibutes 
rtDeclareVariable(Attributes, attrib, attribute attrib, );

RT_PROGRAM void closestHit()
{
    // TODO: calculate the color using the Blinn-Phong reflection model

    const float EPS = 1e-4; // prevent self-shadowing

    float3 result = attrib.emission + attrib.ambient;

    // Point Lights
    int plCount = plights.size();
    for (int i = 0; i < plCount; i++)
    {
        PointLight currP = plights[i];
        float3 lightDir = normalize(currP.point - attrib.intersection);

        // curr position light shadow ray
        ShadowPayload shp;
        shp.isVisible = 1; // assume visibility

        // self-shadowing check --> attrib.intersection + EPS * lightDir
        Ray shadow = make_Ray(attrib.intersection, lightDir, 1, EPS, length(currP.point - attrib.intersection));
        rtTrace(root, shadow, shp);
        // now can check shp for visbility

        if (shp.isVisible)
        {
            // Attenutation Factor
            float L = length(currP.point - attrib.intersection); // just distance from point to intersection (not direction)
            float dropoff = currP.attenuation.x + currP.attenuation.y * L + currP.attenuation.z * L * L;
            // dont want to divide by 0
            float attenFactor = (dropoff < 1e-6f) ? 1.0f : (1.0f / dropoff);

            // Diffuse Factor
            float dotnl = dot(attrib.normal, lightDir);
            dotnl = (dotnl < 0.0f) ? 0.0f : dotnl;
            // component wise multiplication
            float3 diffuseFactor = currP.intensity * attrib.diffuse * dotnl;

            // Specular Factor with half-way vector
            float3 h = normalize(attrib.view + lightDir);
            float dotnh = dot(attrib.normal, h);
            dotnh = (dotnh < 0.0f) ? 0.0f : dotnh;
            float3 specFactor = attrib.specular * currP.intensity * powf(dotnh, attrib.shininess);
            
            result += attenFactor * (diffuseFactor + specFactor);
        }
    }

    // Direction Lights
    int dlCount = dlights.size();
    for (int i = 0; i < dlCount; i++)
    {
        DirectionalLight currD = dlights[i];
        float3 lightDir = normalize(currD.direction);

        ShadowPayload shp;
        shp.isVisible = 1; // assume visibilty
        Ray shadow = make_Ray(attrib.intersection, lightDir, 1, EPS, RT_DEFAULT_MAX);
        rtTrace(root, shadow, shp);
        // now check visibility
        if (shp.isVisible)
        {
            // diffuse factor
            float dotnl = dot(attrib.normal, lightDir);
            dotnl = (dotnl < 0.0f) ? 0.0f : dotnl;
            // component wise mul
            float3 diffuseFactor = attrib.diffuse * currD.intensity * dotnl;

            // specular factor
            float3 h = normalize(attrib.view + lightDir); // half way vector
            float dotnh = dot(attrib.normal, h);
            dotnh = (dotnh < 0.0f) ? 0.0f : dotnh;
            float3 specFactor = attrib.specular * currD.intensity * powf(dotnh, attrib.shininess);
            
            result += (diffuseFactor + specFactor);
        }
    }

    // reflections:
    // calc reflection direction: from incidence/-view and normal
    if (payload.maxdepth > 0)
    {
        float3 rDir = reflect(attrib.view * -1, attrib.normal);

        Payload rp;
        rp.radiance = make_float3(0.0f);
        rp.done = 0;
        rp.maxdepth = payload.maxdepth - 1;

        // send out reflection until depth recursively (iterate until depth limit)
        Ray refRay = make_Ray(attrib.intersection, rDir, 0, EPS, RT_DEFAULT_MAX);
        rtTrace(root, refRay, rp);
        
        result += rp.radiance * attrib.specular;
    }

    payload.radiance = result;
}