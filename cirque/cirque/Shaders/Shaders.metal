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
	return vertexOut;
}

fragment float4 fragment_main(Vertex fragmentIn [[stage_in]],
															constant Uniforms* uniforms [[buffer(1)]])
{
	return float4(0.0, 0.2, 0.8, 1.0);
}

fragment float4 fragment_error(Vertex fragmentIn [[stage_in]],
															constant Uniforms* uniforms [[buffer(1)]])
{
	float g = sin(fragmentIn.position.x);
	return float4(1.0, g, 0.0, 0.8);
}

fragment float4 fragment_bestfit(Vertex fragmentIn [[stage_in]],
															 constant Uniforms* uniforms [[buffer(1)]])
{
	float g = 0.5 * sin(fragmentIn.position.x) + 0.5;
	return float4(0.0, 1.0, 0.0, g);
}
