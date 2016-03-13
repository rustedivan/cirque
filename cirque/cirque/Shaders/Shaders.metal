//
//  Shaders.metal
//  cirque
//
//  Created by Ivan Milles on 07/03/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
	float4 position [[position]];
};

struct Uniforms
{
	float4x4 modelViewProjectionMatrix;
};

vertex Vertex vertex_main(device Vertex* vertices [[buffer(0)]],
													constant Uniforms* uniforms [[buffer(1)]],
													uint vid [[vertex_id]])
{
	Vertex vertexOut;
	vertexOut.position = uniforms->modelViewProjectionMatrix * vertices[vid].position;
	return vertexOut;
}

fragment float4 fragment_main(Vertex inVertex [[stage_in]])
{
	return float4(0.0, 0.2, 0.8, 1.0);
}
