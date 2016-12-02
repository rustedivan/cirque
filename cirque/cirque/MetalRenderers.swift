//
//  MetalRenderer.swift
//  cirque
//
//  Created by Ivan Milles on 2016-11-20.
//  Copyright © 2016 Rusted. All rights reserved.
//


// If building for device (Metal required to compile)
#if !(arch(i386) || arch(x86_64))

import Metal
import UIKit
import simd

// MARK: Metal renderer

protocol MetalRenderer: Renderer {
}
	
struct MetalCircleRenderer: MetalRenderer {
	static let MaxRenderableSegments = 1024
	
	var pipeline: MTLRenderPipelineState!
	
	let vertexBuffer: MTLBuffer
	let uniformBuffer: MTLBuffer
	
	init(device: MTLDevice,
	     pixelFormat: MTLPixelFormat) {
		// TODO: create the vertex buffer here
		
		let shaderLibrary = device.newDefaultLibrary()!
		let vertexFunc = shaderLibrary.makeFunction(name: "vertex_main")
		let fragmentFunc = shaderLibrary.makeFunction(name: "fragment_main")
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction = vertexFunc
		pipelineDescriptor.fragmentFunction = fragmentFunc
		pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
		pipelineDescriptor.sampleCount = 4
		pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

		// Setup buffers
		let uniformBufLen = MemoryLayout<CirqueUniforms>.size
		let vertexBufLen = MemoryLayout<CirqueVertex>.size * MetalCircleRenderer.MaxRenderableSegments * 2
		uniformBuffer = device.makeBuffer(length: uniformBufLen, options: [])
		uniformBuffer.label = "Trail uniforms"
		vertexBuffer = device.makeBuffer(length: vertexBufLen, options: [])
		vertexBuffer.label = "Trail vertices"
	}
	
	func render(vertices: VertexSource,
	            inRenderPass renderPass: RenderPass,
	            intoCommandEncoder commandEncoder: RenderPath.Encoder) {
		
		// Copy vertices to vertex buffer 0
		let vertexArray = vertices.toVertices()
		vertexArray.withUnsafeBytes( { vertexSrc in
			guard let rawVertexSrc = vertexSrc.baseAddress else {
				print("Could not copy vertices into MTLBuffer.")
				return
			}
			
			let vertexDst = vertexBuffer.contents()
			let vertexLen = vertexArray.count * MemoryLayout<CirqueVertex>.stride
			vertexDst.copyBytes(from: rawVertexSrc, count: vertexLen)
		})
		
		// Copy uniforms to vertex buffer 1
		var uniforms = CirqueUniforms()
		
		let uniformsDst = uniformBuffer.contents()
		uniformsDst.copyBytes(from: &uniforms, count: MemoryLayout<CirqueUniforms>.stride)
		
		commandEncoder.setRenderPipelineState(pipeline)
		commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: MetalRenderPath.VertexLocations.position.rawValue)
		commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		commandEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		
		if vertexArray.isEmpty == false {
			commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertexArray.count)
		}
		
	}
}

struct MetalErrorRenderer: MetalRenderer {
	func render(vertices: VertexSource,
	            inRenderPass: RenderPass,
	            intoCommandEncoder: RenderPath.Encoder) {
	}
}
	
#endif
