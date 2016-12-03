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
	func copyVertices(vertices: VertexSource, toBuffer: MTLBuffer) -> Int
}
	
extension MetalRenderer {
	func copyVertices(vertices: VertexSource, toBuffer vertexBuffer: MTLBuffer) -> Int {
		let vertexArray = vertices.toVertices()

		return vertexArray.withUnsafeBytes( { vertexSrc -> Int in
			guard let rawVertexSrc = vertexSrc.baseAddress else {
				print("Could not copy vertices into MTLBuffer \"\(vertexBuffer.label ?? "")\".")
				return 0
			}

			let vertexLen = vertexArray.count * MemoryLayout<CirqueVertex>.stride
			guard vertexLen <= vertexBuffer.length else {
				print("Could not copy \(vertexLen) bytes into MTLBuffer \"\(vertexBuffer.label ?? "")\".")
				return 0
			}
			
			let vertexDst = vertexBuffer.contents()
			vertexDst.copyBytes(from: rawVertexSrc, count: vertexLen)
			
			return vertexArray.count
		})
	}
	
	func copyUniforms(uniforms: CirqueUniforms, toBuffer uniformBuffer: MTLBuffer) {
		let uniformLen = MemoryLayout<CirqueUniforms>.stride
		guard uniformLen <= uniformBuffer.length else {
			print("Could not copy \(uniformLen) bytes into MTLBuffer \"\(uniformBuffer.label ?? "")\".")
			return
		}

		let uniformsDst = uniformBuffer.contents()
		var localUniforms = uniforms
		uniformsDst.copyBytes(from: &localUniforms, count: uniformLen)
	}
}
	
struct MetalCircleRenderer: MetalRenderer {
	static let MaxRenderableSegments = 1024
	
	var pipeline: MTLRenderPipelineState!
	
	let vertexBuffer: MTLBuffer
	let uniformBuffer: MTLBuffer
	
	init(device: MTLDevice,
	     pixelFormat: MTLPixelFormat) {
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
		
		let vertexCount = copyVertices(vertices: vertices, toBuffer: vertexBuffer)
		
		let uniforms = CirqueUniforms()
		copyUniforms(uniforms: uniforms, toBuffer: uniformBuffer)
		
		commandEncoder.setRenderPipelineState(pipeline)
		commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: MetalRenderPath.VertexLocations.position.rawValue)
		commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		commandEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		
		commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertexCount)
	}
}

struct MetalErrorRenderer: MetalRenderer {
	var pipeline: MTLRenderPipelineState!
	
	let vertexBuffer: MTLBuffer
	let uniformBuffer: MTLBuffer
	
	init(device: MTLDevice,
	     pixelFormat: MTLPixelFormat) {
		let shaderLibrary = device.newDefaultLibrary()!
		let vertexFunc = shaderLibrary.makeFunction(name: "vertex_main")
		let fragmentFunc = shaderLibrary.makeFunction(name: "fragment_error")
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
		uniformBuffer.label = "Error uniforms"
		vertexBuffer = device.makeBuffer(length: vertexBufLen, options: [])
		vertexBuffer.label = "Error vertices"
	}
	
	func render(vertices: VertexSource,
	            inRenderPass: RenderPass,
	            intoCommandEncoder commandEncoder: RenderPath.Encoder) {
		
		let vertexCount = copyVertices(vertices: vertices, toBuffer: vertexBuffer)
		
		let uniforms = CirqueUniforms()
		copyUniforms(uniforms: uniforms, toBuffer: uniformBuffer)
		
		commandEncoder.setRenderPipelineState(pipeline)
		commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: MetalRenderPath.VertexLocations.position.rawValue)
		commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		commandEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		
		commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
	}
}
	
#endif
