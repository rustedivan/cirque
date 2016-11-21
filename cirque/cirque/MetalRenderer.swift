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

struct MetalRenderer: Renderer {
	let metalLayer: CAMetalLayer
	
	let device: MTLDevice
	var commandQueue: MTLCommandQueue!
	var commandBuffer: MTLCommandBuffer!
	
	var multisampleRenderTarget: MTLTexture!
	var pipeline: MTLRenderPipelineState!
	
	var uniforms: CirqueUniforms
	
	var renderTargetSize: CGSize {
		get { return metalLayer.bounds.size }
		set {
			metalLayer.bounds.size = newValue
			multisampleRenderTarget = buildRenderTarget(renderTargetSize: newValue)
		}
	}
	
	init(layer: CAMetalLayer) {
		device = MTLCreateSystemDefaultDevice()!
		metalLayer = layer
		uniforms = CirqueUniforms()
		
		// Setup Metal CALayer
		metalLayer.device = device
		metalLayer.pixelFormat = .bgra8Unorm
		
		// Setup render pipeline
		let metalLibrary = device.newDefaultLibrary()!
		let vertexFunc = metalLibrary.makeFunction(name: "vertex_main")
		let fragmentFunc = metalLibrary.makeFunction(name: "fragment_main")
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction = vertexFunc
		pipelineDescriptor.fragmentFunction = fragmentFunc
		pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
		pipelineDescriptor.sampleCount = 4
		
		pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
		
		// Setup command buffer
		commandQueue = device.makeCommandQueue()
	}
	
	func render(_ vertices: VertexSource) {
		let vertexArray = vertices.toVertices()
		
		// Fill out vertex buffer
		let trailBuffer = device.makeBuffer(bytes: vertexArray,
		                                            length: MemoryLayout<CirqueVertex>.size * vertexArray.count,
		                                            options: [])
		
		// Setup ink render pass
		let drawable = metalLayer.nextDrawable()!
		let colorAttachmentDescriptor = MTLRenderPassColorAttachmentDescriptor()
		colorAttachmentDescriptor.loadAction = .clear
		colorAttachmentDescriptor.storeAction = .multisampleResolve
		colorAttachmentDescriptor.texture = multisampleRenderTarget
		colorAttachmentDescriptor.resolveTexture = drawable.texture
		colorAttachmentDescriptor.clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
		
		// Render buffer into ink render pass
		var circlePassDescriptor: MTLRenderPassDescriptor
		circlePassDescriptor = MTLRenderPassDescriptor()
		circlePassDescriptor.colorAttachments[0] = colorAttachmentDescriptor
		
		let commandBuffer = commandQueue.makeCommandBuffer()
		let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: circlePassDescriptor)
		
		commandEncoder.setRenderPipelineState(pipeline)
		
		var localUniforms = uniforms
		withUnsafeMutablePointer(to: &localUniforms) { uniformsPtr in
			let uniformBuffer = device.makeBuffer(bytesNoCopy: uniformsPtr,
																						length: MemoryLayout<CirqueUniforms>.size,
																						options: [],
																						deallocator: nil)
			commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
		}
		
		commandEncoder.setVertexBuffer(trailBuffer, offset: 0, at: 0)
		if vertexArray.isEmpty == false {
			commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertexArray.count)
		}
		commandEncoder.endEncoding()
		
		commandBuffer.present(drawable)
		
		commandBuffer.commit()
	}
	
	private func buildRenderTarget(renderTargetSize size: CGSize) -> MTLTexture {
		let targetDescriptor = MTLTextureDescriptor()
		targetDescriptor.pixelFormat = metalLayer.pixelFormat
		targetDescriptor.sampleCount = 4
		targetDescriptor.textureType = .type2DMultisample
		targetDescriptor.width = Int(size.width)
		targetDescriptor.height = Int(size.height)
		return device.makeTexture(descriptor: targetDescriptor)
	}
}

func ortho2d(l: Float, r: Float, b: Float, t: Float, n: Float, f: Float) -> matrix_float4x4 {
	let width = 1.0 / (r - l)
	let height = 1.0 / (t - b)
	let depth = 1.0 / (f - n)
	
	var p = float4(0.0)
	var q = float4(0.0)
	var r = float4(0.0)
	var s = float4(0.0)
	
	p.x = 2.0 * width
	q.y = 2.0 * height
	r.z = depth
	s.z = -n * depth
	s.w = 1.0
	
	return matrix_float4x4(columns: (p, q, r, s))
}

#endif
