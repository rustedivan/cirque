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
				print("Could not copy vertices into MTLBuffer pointer \"\(vertexBuffer.label ?? "")\".")
				return 0
			}

			let vertexLen = vertexArray.count * MemoryLayout<CirqueVertex>.stride
			guard vertexLen <= vertexBuffer.length else {
				print("Could not fit \(vertexLen) vertex bytes into MTLBuffer \"\(vertexBuffer.label ?? "")\".")
				return 0
			}
			
			let vertexDst = vertexBuffer.contents()
			vertexDst.copyBytes(from: rawVertexSrc, count: vertexLen)
			
			return vertexArray.count
		})
	}
	
	func copyUniforms<UniformBlock>(uniforms: UniformBlock, toBuffer uniformBuffer: MTLBuffer) {
		let uniformLen = MemoryLayout<UniformBlock>.stride
		guard uniformLen <= uniformBuffer.length else {
			print("Could not copy \(uniformLen) uniform bytes into MTLBuffer \"\(uniformBuffer.label ?? "")\".")
			return
		}

		let uniformsDst = uniformBuffer.contents()
		var localUniforms = uniforms
		uniformsDst.copyBytes(from: &localUniforms, count: uniformLen)
	}
}
	
struct MetalTrailRenderer<Encoder>: MetalRenderer {
	let MaxRenderableSegments = 10240
	
	var pipeline: MTLRenderPipelineState!
	
	let vertexBuffer: MTLBuffer
	let uniformBuffer: MTLBuffer
	
	init(device: MTLDevice,
	     pixelFormat: MTLPixelFormat) {
		let shaderLibrary = device.newDefaultLibrary()!
		let vertexFunc = shaderLibrary.makeFunction(name: "vertex_main")
		let fragmentFunc = shaderLibrary.makeFunction(name: "fragment_trail")
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction = vertexFunc
		pipelineDescriptor.fragmentFunction = fragmentFunc
		pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
		pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
		pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
		pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
		pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
		pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
		pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
		pipelineDescriptor.sampleCount = 4
		pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

		// Setup buffers
		let uniformBufLen = MemoryLayout<TrailUniforms>.size
		let vertexBufLen = MemoryLayout<CirqueVertex>.size * MaxRenderableSegments * 2
		uniformBuffer = device.makeBuffer(length: uniformBufLen, options: [])
		uniformBuffer.label = "Trail uniforms"
		vertexBuffer = device.makeBuffer(length: vertexBufLen, options: [])
		vertexBuffer.label = "Trail vertices"
	}
	
	func render(vertices: VertexSource,
	            withUniforms uniforms: TrailUniforms,
	            intoEncoder encoder: MTLRenderCommandEncoder) {
		
		let vertexCount = copyVertices(vertices: vertices, toBuffer: vertexBuffer)
		
//		copyUniforms(uniforms: uniforms, toBuffer: uniformBuffer)
		
		encoder.setRenderPipelineState(pipeline)
		encoder.setVertexBuffer(vertexBuffer, offset: 0, at: MetalRenderPath.VertexLocations.position.rawValue)
//		encoder.setVertexBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		encoder.setFragmentBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		
		encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertexCount)
	}
}
	
struct MetalBestFitRenderer<Encoder>: MetalRenderer {
	let MaxRenderableSegments = 1024
	
	var pipeline: MTLRenderPipelineState!
	
	let vertexBuffer: MTLBuffer
	let uniformBuffer: MTLBuffer
	
	init(device: MTLDevice,
			 pixelFormat: MTLPixelFormat) {
		let shaderLibrary = device.newDefaultLibrary()!
		let vertexFunc = shaderLibrary.makeFunction(name: "vertex_main")
		let fragmentFunc = shaderLibrary.makeFunction(name: "fragment_bestfit")
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction = vertexFunc
		pipelineDescriptor.fragmentFunction = fragmentFunc
		pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
		pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
		pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
		pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
		pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
		pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
		pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
		pipelineDescriptor.sampleCount = 4
		pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
		
		// Setup buffers
		let uniformBufLen = MemoryLayout<BestFitUniforms>.size
		let vertexBufLen = MemoryLayout<CirqueVertex>.size * MaxRenderableSegments * 2
		uniformBuffer = device.makeBuffer(length: uniformBufLen, options: [])
		uniformBuffer.label = "BestFit uniforms"
		vertexBuffer = device.makeBuffer(length: vertexBufLen, options: [])
		vertexBuffer.label = "BestFit vertices"
	}
	
	func render(vertices: VertexSource,
	            withUniforms uniforms: BestFitUniforms,
							intoEncoder encoder: MTLRenderCommandEncoder) {
		
		let vertexCount = copyVertices(vertices: vertices, toBuffer: vertexBuffer)
		
		// TODO: typealias the uniform block type across the renderer
		copyUniforms(uniforms: uniforms, toBuffer: uniformBuffer)
		encoder.setRenderPipelineState(pipeline)
		encoder.setVertexBuffer(vertexBuffer, offset: 0, at: MetalRenderPath.VertexLocations.position.rawValue)
		encoder.setVertexBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		encoder.setFragmentBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		
		encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertexCount)
	}
}

struct MetalErrorRenderer<Encoder>: MetalRenderer {
	let MaxRenderableSegments = 1024
	
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
		pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
		pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
		pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
		pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
		pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
		pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
		pipelineDescriptor.sampleCount = 4
		pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
		
		// Setup buffers
		let uniformBufLen = MemoryLayout<ErrorAreaUniforms>.size
		let vertexBufLen = MemoryLayout<CirqueVertex>.size * MaxRenderableSegments * 2
		uniformBuffer = device.makeBuffer(length: uniformBufLen, options: [])
		uniformBuffer.label = "Error uniforms"
		vertexBuffer = device.makeBuffer(length: vertexBufLen, options: [])
		vertexBuffer.label = "Error vertices"
	}
	
	func render(vertices: VertexSource,
	            withUniforms uniforms: ErrorAreaUniforms,
	            intoEncoder encoder: MTLRenderCommandEncoder) {
		
		let vertexCount = copyVertices(vertices: vertices, toBuffer: vertexBuffer)
		
		copyUniforms(uniforms: uniforms, toBuffer: uniformBuffer)
		encoder.setRenderPipelineState(pipeline)
		encoder.setVertexBuffer(vertexBuffer, offset: 0, at: MetalRenderPath.VertexLocations.position.rawValue)
		encoder.setVertexBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		encoder.setFragmentBuffer(uniformBuffer, offset: 0, at: MetalRenderPath.VertexLocations.uniforms.rawValue)
		
		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
	}
}
	
#endif
