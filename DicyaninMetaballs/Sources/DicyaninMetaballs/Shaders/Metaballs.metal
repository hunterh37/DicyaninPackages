#include <metal_stdlib>
#include "MarchingCubesTables.h"
using namespace metal;

// Must match MetaballShaderTypes.swift layouts exactly.

struct MetaballGPU {
    float4 positionRadius;   // xyz position (field local), w radius
    float4 params;           // x strength, yzw reserved
};

struct FieldUniforms {
    float3 boundsMin;
    uint   ballCount;
    float3 cellSize;
    float  isoValue;
    uint3  gridSize;         // sample points per axis
    uint   maxVertices;
    float4 color;            // reserved for vertex color pipelines
};

struct MetaballVertex {
    packed_float3 position;
    packed_float3 normal;
};

// Wyvill soft-object falloff: C2 continuous, zero outside radius, cheap.
inline float fieldContribution(float distSq, float radius, float strength) {
    float r2 = radius * radius;
    if (distSq >= r2) { return 0.0; }
    float t = 1.0 - distSq / r2;
    return strength * t * t * t;
}

inline uint fieldIndex(uint3 p, uint3 gridSize) {
    return (p.z * gridSize.y + p.y) * gridSize.x + p.x;
}

// Pass 1: evaluate the scalar field at every grid sample point.
kernel void metaballField(
    device float *field                    [[buffer(0)]],
    constant MetaballGPU *balls            [[buffer(1)]],
    constant FieldUniforms &u              [[buffer(2)]],
    uint3 gid                              [[thread_position_in_grid]])
{
    if (any(gid >= u.gridSize)) { return; }
    float3 p = u.boundsMin + float3(gid) * u.cellSize;
    float value = 0.0;
    for (uint i = 0; i < u.ballCount; i++) {
        MetaballGPU b = balls[i];
        float3 d = p - b.positionRadius.xyz;
        value += fieldContribution(dot(d, d), b.positionRadius.w, b.params.x);
    }
    field[fieldIndex(gid, u.gridSize)] = value;
}

inline float sampleField(device const float *field, int3 p, uint3 gridSize) {
    int3 c = clamp(p, int3(0), int3(gridSize) - 1);
    return field[fieldIndex(uint3(c), gridSize)];
}

// Central-difference gradient for smooth per-vertex normals.
inline float3 fieldGradient(device const float *field, float3 cellPos, uint3 gridSize) {
    int3 p = int3(cellPos + 0.5);
    float dx = sampleField(field, p + int3(1,0,0), gridSize) - sampleField(field, p - int3(1,0,0), gridSize);
    float dy = sampleField(field, p + int3(0,1,0), gridSize) - sampleField(field, p - int3(0,1,0), gridSize);
    float dz = sampleField(field, p + int3(0,0,1), gridSize) - sampleField(field, p - int3(0,0,1), gridSize);
    return float3(dx, dy, dz);
}

inline float3 vertexLerp(float iso, float3 p1, float3 p2, float v1, float v2) {
    float denom = v2 - v1;
    float t = (abs(denom) > 1e-6) ? clamp((iso - v1) / denom, 0.0, 1.0) : 0.5;
    return mix(p1, p2, t);
}

// Bourke corner ordering.
constant int3 cornerOffsets[8] = {
    int3(0,0,0), int3(1,0,0), int3(1,0,1), int3(0,0,1),
    int3(0,1,0), int3(1,1,0), int3(1,1,1), int3(0,1,1)
};

constant int2 edgeCorners[12] = {
    int2(0,1), int2(1,2), int2(2,3), int2(3,0),
    int2(4,5), int2(5,6), int2(6,7), int2(7,4),
    int2(0,4), int2(1,5), int2(2,6), int2(3,7)
};

// Pass 2: marching cubes. One thread per cell, appends triangles.
kernel void metaballMarchingCubes(
    device const float *field              [[buffer(0)]],
    constant FieldUniforms &u              [[buffer(2)]],
    device MetaballVertex *vertices        [[buffer(3)]],
    device atomic_uint *vertexCounter      [[buffer(4)]],
    uint3 gid                              [[thread_position_in_grid]])
{
    if (any(gid >= u.gridSize - 1)) { return; }

    float corner[8];
    float3 cornerCell[8];
    int cubeIndex = 0;
    for (int i = 0; i < 8; i++) {
        int3 c = int3(gid) + cornerOffsets[i];
        corner[i] = field[fieldIndex(uint3(c), u.gridSize)];
        cornerCell[i] = float3(c);
        if (corner[i] < u.isoValue) { cubeIndex |= (1 << i); }
    }

    ushort edges = mcEdgeTable[cubeIndex];
    if (edges == 0) { return; }

    float3 edgeVertexCell[12];
    for (int e = 0; e < 12; e++) {
        if (edges & (1 << e)) {
            int a = edgeCorners[e].x;
            int b = edgeCorners[e].y;
            edgeVertexCell[e] = vertexLerp(u.isoValue, cornerCell[a], cornerCell[b], corner[a], corner[b]);
        }
    }

    constant char *tris = mcTriTable[cubeIndex];
    for (int t = 0; t < 16 && tris[t] != -1; t += 3) {
        uint base = atomic_fetch_add_explicit(vertexCounter, 3u, memory_order_relaxed);
        if (base + 3 > u.maxVertices) {
            atomic_fetch_sub_explicit(vertexCounter, 3u, memory_order_relaxed);
            return;
        }
        for (int k = 0; k < 3; k++) {
            float3 cell = edgeVertexCell[tris[t + k]];
            float3 pos = u.boundsMin + cell * u.cellSize;
            float3 grad = fieldGradient(field, cell, u.gridSize);
            float len = length(grad);
            // Field decreases outward, so the outward normal is -gradient.
            float3 n = (len > 1e-6) ? (-grad / len) : float3(0, 1, 0);
            vertices[base + k].position = pos;
            vertices[base + k].normal = n;
        }
    }
}
