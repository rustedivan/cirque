//
//  CirqueView.swift
//  cirque
//
//  Created by Ivan Milles on 24/01/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Metal
import UIKit
import QuartzCore
import simd

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

struct CirqueUniforms {
	var modelViewProjection: matrix_float4x4
}

struct CirqueVertex {
	let position: vector_float4
}

class CirqueView: UIView {
	let device: MTLDevice
	var commandQueue: MTLCommandQueue!
	var commandBuffer: MTLCommandBuffer!
	
	var multisampleRenderTarget: MTLTexture!
	var circlePassDescriptor: MTLRenderPassDescriptor!
	var pipeline: MTLRenderPipelineState!
	
	var uniforms: CirqueUniforms
	
	var metalLayer: CAMetalLayer {
		return layer as! CAMetalLayer
	}
	
	override class func layerClass() -> AnyClass {
		return CAMetalLayer.self
	}
	
	required init?(coder aDecoder: NSCoder) {
		device = MTLCreateSystemDefaultDevice()!
		uniforms = CirqueUniforms(modelViewProjection: matrix_identity_float4x4)
		super.init(coder: aDecoder)
	}

	override func layoutSublayersOfLayer(layer: CALayer) {
		super.layoutSublayersOfLayer(layer)

		metalLayer.frame = layer.bounds
		metalLayer.drawableSize = CGSize(width: layer.bounds.width * contentScaleFactor, height: layer.bounds.height * contentScaleFactor)
		multisampleRenderTarget = buildRenderTarget(metalLayer.drawableSize)
		
		var mvpMatrix = ortho2d(0.0, r: Float(layer.bounds.width), b: Float(layer.bounds.height), t: 0.0, n: 0.0, f: 1.0)
		// Translate into Metal's NDC space (2x2x1 unit cube)
		mvpMatrix.columns.3.x = -1.0
		mvpMatrix.columns.3.y = +1.0
		uniforms.modelViewProjection = mvpMatrix
	}
	
	override func didMoveToWindow() {
		// Setup Metal CALayer
		metalLayer.device = device
		metalLayer.pixelFormat = .BGRA8Unorm
		contentScaleFactor = 2.0
		
		// Setup render pipeline
		let metalLibrary = device.newDefaultLibrary()!
		let vertexFunc = metalLibrary.newFunctionWithName("vertex_main")
		let fragmentFunc = metalLibrary.newFunctionWithName("fragment_main")
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction = vertexFunc
		pipelineDescriptor.fragmentFunction = fragmentFunc
		pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
		pipelineDescriptor.sampleCount = 4

		pipeline = try! device.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
		
		// Setup command buffer
		commandQueue = device.newCommandQueue()
	}
	
	// Build multisample render target
	func buildRenderTarget(size: CGSize) -> MTLTexture? {
		let targetDescriptor = MTLTextureDescriptor()
		targetDescriptor.pixelFormat = metalLayer.pixelFormat
		targetDescriptor.sampleCount = 4
		targetDescriptor.textureType = .Type2DMultisample
		targetDescriptor.width = Int(size.width)
		targetDescriptor.height = Int(size.height)
		return device.newTextureWithDescriptor(targetDescriptor)
	}

	func render(model: Circle, withThickness thickness: Double) {
		let vertices = trailToInkVertices(model.segments, withTickness: thickness)
		
		// Fill out vertex buffer
		let trailBuffer = device.newBufferWithBytes(vertices,
			length: sizeof(CirqueVertex) * vertices.count,
			options: MTLResourceOptions.CPUCacheModeDefaultCache)
		
		// Setup ink render pass
		let drawable = metalLayer.nextDrawable()!
		let colorAttachmentDescriptor = MTLRenderPassColorAttachmentDescriptor()
		colorAttachmentDescriptor.loadAction = .Clear
		colorAttachmentDescriptor.storeAction = .MultisampleResolve
		colorAttachmentDescriptor.texture = multisampleRenderTarget
		colorAttachmentDescriptor.resolveTexture = drawable.texture
		colorAttachmentDescriptor.clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
		
		// Render buffer into ink render pass
		circlePassDescriptor = MTLRenderPassDescriptor()
		circlePassDescriptor.colorAttachments[0] = colorAttachmentDescriptor

		let commandBuffer = commandQueue.commandBuffer()
		let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(circlePassDescriptor)

		commandEncoder.setRenderPipelineState(pipeline)

		// Setup uniform buffer
		withUnsafePointer(&uniforms) { uniformsPtr in
			let uniformBuffer = device.newBufferWithBytes(uniformsPtr,
				length: sizeof(CirqueUniforms),
				options: MTLResourceOptions.CPUCacheModeDefaultCache)
			commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, atIndex: 1)
		}
		
		commandEncoder.setVertexBuffer(trailBuffer, offset: 0, atIndex: 0)
		if vertices.isEmpty == false {
			commandEncoder.drawPrimitives(.TriangleStrip, vertexStart: 0, vertexCount: vertices.count)
		}
		commandEncoder.endEncoding()

		commandBuffer.presentDrawable(drawable)

		commandBuffer.commit()
	}
	
	func renderFit(withRadius radius: Double, at: CGPoint) {
	}
	
	func trailToInkVertices(trail: Trail, withTickness thickness: Double) -> [CirqueVertex] {
		// Inner and outer vertices for each segment
		// $ lazy generate pls
		let segments = zip(trail.angles, trail.distances)
		let stroke = zip(trail.points, segments)
		
		var vertices: [CirqueVertex] = []
		
		for segment in stroke {
			let pC = segment.0
			let angle = segment.1.0
			let length = segment.1.1
			let width = CGFloat(thickness) + log2(length)
			let span = CGVector(dx: sin(angle) * width / 2.0, dy: -cos(angle) * width / 2.0)

			let pL = CirqueVertex(position: vector_float4(Float(pC.x + span.dx), Float(pC.y + span.dy), 0.0, 1.0))
			let pR = CirqueVertex(position: vector_float4(Float(pC.x - span.dx), Float(pC.y - span.dy), 0.0, 1.0))
			
			vertices.append(pL)
			vertices.append(pR)
		}
		
		return vertices
	}
}
