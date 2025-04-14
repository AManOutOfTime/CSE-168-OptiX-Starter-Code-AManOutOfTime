#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different geometries should be defined here.
 */

struct Triangle
{
    

    // TODO: define the triangle structure
    optix::float3 vert0;
    optix::float3 vert1;
    optix::float3 vert2;

    optix::float3 ambient;

};

struct Sphere
{


    // TODO: define the sphere structure
    optix::float3 center;
    float radius;
    optix::float3 ambient;

    optix::Matrix4x4 transform;
    optix::Matrix4x4 inv_transform;
};

struct Attributes
{
    
    optix::float3 ambient;
    // TODO: define the attributes structure
};