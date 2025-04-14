#include <optix.h>
#include <optix_device.h>
#include "Geometries.h"

using namespace optix;

rtBuffer<Sphere> spheres; // a buffer of all spheres

rtDeclareVariable(Ray, ray, rtCurrentRay, );

// Attributes to be passed to material programs 
rtDeclareVariable(Attributes, attrib, attribute attrib, );

RT_PROGRAM void intersect(int primIndex)
{
    // Find the intersection of the current ray and sphere
    Sphere sphere = spheres[primIndex];
    float t;

    // TODO: implement sphere intersection test here
    // apply sphere transform to each ray intersection
    // with transform calc'd t is in sphere space need to transform back to world
    float3 p0 = make_float3(sphere.inv_transform * make_float4(ray.origin, 1.0f));
    float3 dir = normalize(make_float3(sphere.inv_transform * make_float4(ray.direction, 0.0f)));
    // sphere center = origin in sphere space
    float3 c = sphere.center;
    float r = sphere.radius;

    float discrim = (dot(dir, (p0 - c)) * dot(dir, (p0 - c))) - (length(p0 - c) * length(p0 - c)) + (r * r);

    if (discrim < 0.0f) // no intersection
        return;
    else if (discrim == 0.0f) // 1 intersection - tangent
    {
        t = dot(-dir, (p0 - c)); // discrim is 0.0f
        if (t <= 0)
            return;
    }
    else // positive discrim, two intersection
    {
        // two possible choices - get smaller positive root
        float t1 = dot(-1 * dir, (p0 - c)) + sqrt(discrim);
        float t2 = dot(-1 * dir, (p0 - c)) - sqrt(discrim);

        if (t1 > 0.0f && t2 > 0.0f)
        {
            t = (t1 > t2) ? t2 : t1;
        }
        else if (t1 > 0.0f)
        {
            t = t1;
        }
        else if (t2 > 0.0f)
        {
            t = t2;
        }
        else
            return;
    }

    float3 sphereHit = (p0 - c) + t * dir;
    float3 worldHit = make_float3(sphere.transform * make_float4(sphereHit, 1.0f));
    float worldT = length(worldHit - ray.origin);

    // Report intersection (material programs will handle the rest)
    if (rtPotentialIntersection(worldT))
    {
        // Pass attributes

        // TODO: assign attribute variables here
        attrib.ambient = sphere.ambient;
        rtReportIntersection(0);
    }
}

RT_PROGRAM void bound(int primIndex, float result[6])
{
    Sphere sphere = spheres[primIndex];

    // TODO: implement sphere bouding box
    result[0] = -1000.f;
    result[1] = -1000.f;
    result[2] = -1000.f;
    result[3] = 1000.f;
    result[4] = 1000.f;
    result[5] = 1000.f;
}