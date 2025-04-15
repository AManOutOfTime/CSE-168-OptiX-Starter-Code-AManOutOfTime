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

    // ray-sphere intersection equation
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
        attrib.intersection = worldHit; // where intersection happens in world
        // sphere center and radius is sphere world need to convert to real world
        float3 normalSphere = normalize(sphereHit - sphere.center); // normal in sphere world
        // use inverse transpose to convert normal in object space to world space

        // get transpose of sphere.inv_transform:
        optix::Matrix4x4 invtrans;

        optix::float4 row0 = sphere.inv_transform.getRow(0);
        optix::float4 row1 = sphere.inv_transform.getRow(1);
        optix::float4 row2 = sphere.inv_transform.getRow(2);
        optix::float4 row3 = sphere.inv_transform.getRow(3);

        invtrans.setRow(0, make_float4(row0.x, row1.x, row2.x, row3.x));
        invtrans.setRow(1, make_float4(row0.y, row1.y, row2.y, row3.y));
        invtrans.setRow(2, make_float4(row0.z, row1.z, row2.z, row3.z));
        invtrans.setRow(3, make_float4(row0.w, row1.w, row2.w, row3.w));

        float4 normalWorld = invtrans * make_float4(normalSphere, 0.0f);
        attrib.normal = normalize(make_float3(normalWorld)); // normal in real world

        attrib.view = normalize(ray.origin - worldHit); // add view ray

        attrib.ambient = sphere.attrib.ambient;
        attrib.diffuse = sphere.attrib.diffuse;
        attrib.shininess = sphere.attrib.shininess;
        attrib.specular = sphere.attrib.specular;
        attrib.emission = sphere.attrib.emission;
        rtReportIntersection(0);
    }
}

RT_PROGRAM void bound(int primIndex, float result[6])
{
    Sphere sphere = spheres[primIndex];

    // using unit sphere in sphere world need to convert to world space
    // convert all corners of bounding box to cover sphere and then check for min/max
    float3 box[8];
    box[0] = make_float3(-1.0f, -1.0f, -1.0f);
    box[1] = make_float3(1.0f, -1.0f, -1.0f);
    box[2] = make_float3(-1.0f, 1.0f, -1.0f);
    box[3] = make_float3(-1.0f, -1.0f, 1.0f);
    box[4] = make_float3(1.0f, 1.0f, -1.0f);
    box[5] = make_float3(1.0f, -1.0f, 1.0f);
    box[6] = make_float3(-1.0f, 1.0f, 1.0f);
    box[7] = make_float3(1.0f, 1.0f, 1.0f);
    // TODO: implement sphere bouding box

    float3 tbox[8];
    for (int i = 0; i < 8; i++)
    {
        tbox[i] = make_float3(sphere.transform * make_float4(box[i], 1.0f));
    }

    float3 min = tbox[0];
    float3 max = tbox[0];
    for (int i = 1; i < 8; i++)
    {
        min = fminf(min, tbox[i]);
        max = fmaxf(max, tbox[i]);
    }

    result[0] = min.x;
    result[1] = min.y;
    result[2] = min.z;
    result[3] = max.x;
    result[4] = max.y;
    result[5] = max.z;
}