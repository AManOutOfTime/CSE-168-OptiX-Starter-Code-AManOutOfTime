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
    float3 p0 = ray.origin;
    float3 dir = ray.direction;
    float3 c = sphere.center;
    float r = sphere.radius;

    float discrim = pow( dot(dir, (p0 - c)) , 2.0f ) - pow(length(p0 - c) , 2.0f) + pow(r, 2.0f);

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

    // Report intersection (material programs will handle the rest)
    if (rtPotentialIntersection(t))
    {
        // Pass attributes

        // TODO: assign attribute variables here

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