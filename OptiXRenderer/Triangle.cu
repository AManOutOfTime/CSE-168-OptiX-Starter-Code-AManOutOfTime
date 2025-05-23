#include "optix.h"
#include "optix_device.h"
#include "Geometries.h"

using namespace optix;

rtBuffer<Triangle> triangles; // a buffer of all spheres

rtDeclareVariable(Ray, ray, rtCurrentRay, );

// Attributes to be passed to material programs 
rtDeclareVariable(Attributes, attrib, attribute attrib, );

RT_PROGRAM void intersect(int primIndex)
{
    // Find the intersection of the current ray and triangle
    Triangle tri = triangles[primIndex];
    float t;

    // TODO: implement triangle intersection test here
    // ray components
    float3 p0 = ray.origin;
    float3 dir = ray.direction;

    // setup matrix for barycentric equation
    Matrix4x4 p;

    p.setRow(0, make_float4(tri.vert0.x, tri.vert1.x, tri.vert2.x, -1*dir.x));
    p.setRow(1, make_float4(tri.vert0.y, tri.vert1.y, tri.vert2.y, -1*dir.y));
    p.setRow(2, make_float4(tri.vert0.z, tri.vert1.z, tri.vert2.z, -1*dir.z));
    p.setRow(3, make_float4(1.0f, 1.0f, 1.0f, 0.0f));

    
    
    

    // homogenization
    float4 p00 = make_float4(p0, 1.0f);

    // DEBUG: p00 printout
    //rtPrintf("p00: (%f, %f, %f, %f)\n", p00.x, p00.y, p00.z, p00.w);


    Matrix4x4 invp = p.inverse();

    /*
    // DEBUG: p print out 
    for (int i = 0; i < 4; ++i) {
        rtPrintf("Row %d: %f %f %f %f\n", i,
            p[i * 4 + 0],
            p[i * 4 + 1],
            p[i * 4 + 2],
            p[i * 4 + 3]
        );
    }
    rtPrintf("\n\n");
    */

    float4 ans = invp * p00;

    // components
    float lambda1 = ans.x;
    float lambda2 = ans.y;
    float lambda3 = ans.z;
    t = ans.w;
    //rtPrintf("%f\n", t);
    if (lambda1 < 0.0f || lambda2 < 0.0f || lambda3 < 0.0f)
    {
        // DEBUG
        //rtPrintf("Lambda less than 0 fail for triangle %f", primIndex);
        return;
    }
    if (t < 0.0f)
    {
        //rtPrintf("t less than 0 fail for triangle %f", primIndex);
        return;
    }

    // Report intersection (material programs will handle the rest)
    //rtPrintf("t precheck %f", t);
    if (rtPotentialIntersection(t))
    {
        //rtPrintf("t confirmed postcheck %f", t);
        // Pass attributes
        // TODO: assign attribute variables here
        float3 intersect = p0 + t * dir;
        attrib.intersection = intersect;

        // normal for triangle
        float3 triNormal = normalize( cross(tri.vert1 - tri.vert0, tri.vert2 - tri.vert0) );
        attrib.normal = triNormal;

        // for reflections/specular
        attrib.view = normalize(p0 - intersect);

        attrib.ambient = tri.attrib.ambient;
        attrib.diffuse = tri.attrib.diffuse;
        attrib.shininess = tri.attrib.shininess;
        attrib.specular = tri.attrib.specular;
        attrib.emission = tri.attrib.emission;

        rtReportIntersection(0);
    }
}

RT_PROGRAM void bound(int primIndex, float result[6])
{
    Triangle tri = triangles[primIndex];

    // TODO: implement triangle bouding box
    // only vertices can be min/max

    // use optix min and max functions
    float3 min = fminf(fminf(tri.vert0, tri.vert1), tri.vert2);
    float3 max = fmaxf(fmaxf(tri.vert0, tri.vert1), tri.vert2);


    result[0] = min.x;
    result[1] = min.y;
    result[2] = min.z;
    result[3] = max.x;
    result[4] = max.y;
    result[5] = max.z;
}