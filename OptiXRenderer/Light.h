#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different light sources should be defined here.
 */

struct PointLight // in scene with reducing intensity (attenuation)
{


    // TODO: define the point light structure
    optix::float3 point;
    optix::float3 intensity;
    // const, lin, quad
    optix::float3 attenuation;

};

struct DirectionalLight // from infinity with non-decreasing radiance
{


    // TODO: define the directional light structure
    optix::float3 direction;
    optix::float3 intensity;

};