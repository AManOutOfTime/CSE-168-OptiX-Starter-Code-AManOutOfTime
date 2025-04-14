#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different geometries should be defined here.
 */

struct Attributes
{

    // TODO: define the attributes structure
    optix::float3 ambient;
    optix::float3 diffuse;
    float shininess;
    optix::float3 specular;
    optix::float3 emission;
};

struct Triangle
{
    

    // TODO: define the triangle structure
    optix::float3 vert0;
    optix::float3 vert1;
    optix::float3 vert2;

    Attributes attrib;

};

struct Sphere
{

    // TODO: define the sphere structure
    optix::float3 center;
    float radius;
    Attributes attrib;

    optix::Matrix4x4 transform;
    optix::Matrix4x4 inv_transform;
};

