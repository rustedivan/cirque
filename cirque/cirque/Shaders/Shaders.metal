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
	float4 color;
};

struct Uniforms {
	float progress;
};

struct Constants
{
	float4x4 modelViewProjectionMatrix;
};

vertex Vertex vertex_main(device Vertex* vertices [[buffer(0)]],
													constant Uniforms* uniforms [[buffer(1)]],
													constant Constants* constants [[buffer(2)]],
													uint vid [[vertex_id]])
{
	Vertex vertexOut;
	vertexOut.position = constants->modelViewProjectionMatrix * vertices[vid].position;
	vertexOut.color = vertices[vid].color;
	return vertexOut;
}

fragment float4 fragment_trail(Vertex fragmentIn [[stage_in]],
															constant Uniforms* uniforms [[buffer(1)]])
{
	return fragmentIn.color;
}

fragment float4 fragment_error(Vertex fragmentIn [[stage_in]],
															constant Uniforms* uniforms [[buffer(1)]])
{
	return fragmentIn.color;
}

fragment float4 fragment_bestfit(Vertex fragmentIn [[stage_in]],
															 constant Uniforms* uniforms [[buffer(1)]])
{
	return fragmentIn.color;
}
