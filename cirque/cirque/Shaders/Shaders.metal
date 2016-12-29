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

struct Constants
{
	float4x4 modelViewProjectionMatrix;
};

vertex Vertex vertex_main(device Vertex* vertices [[buffer(0)]],
													constant Constants* constants [[buffer(2)]],
													uint vid [[vertex_id]])
{
	Vertex vertexOut;
	vertexOut.position = constants->modelViewProjectionMatrix * vertices[vid].position;
	vertexOut.color = vertices[vid].color;
	return vertexOut;
}

struct TrailUniforms {
};

fragment float4 fragment_trail(Vertex fragmentIn [[stage_in]],
															constant TrailUniforms* uniforms [[buffer(1)]])
{
	return fragmentIn.color;
}

struct ErrorAreaUniforms {
	float progress;
	float errorFlashIntensity;
};

fragment float4 fragment_error(Vertex fragmentIn [[stage_in]],
															constant ErrorAreaUniforms* uniforms [[buffer(1)]])
{
	float alpha = fragmentIn.color.w + uniforms->progress;
	return float4(fragmentIn.color.x, fragmentIn.color.y, fragmentIn.color.z, alpha);
}

struct BestFitUniforms {
	float progress;
	float quality;
};

fragment float4 fragment_bestfit(Vertex fragmentIn [[stage_in]],
															 constant BestFitUniforms* uniforms [[buffer(1)]])
{
	float alpha = (fragmentIn.color.w < uniforms->progress) ? 0.0 : 1.0;
	return float4(fragmentIn.color.x, fragmentIn.color.y, fragmentIn.color.z, alpha);
}
