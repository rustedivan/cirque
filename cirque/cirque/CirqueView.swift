//
//  CirqueView.swift
//  cirque
//
//  Created by Ivan Milles on 24/01/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

import UIKit
import simd
import Metal
import QuartzCore

struct CirqueUniforms {
	var modelViewProjection: matrix_float4x4
}

struct CirqueVertex {
	let position: vector_float4
}

extension CGPoint {
	init(vertex: CirqueVertex) {
		self.init(x: CGFloat(vertex.position.x), y: CGFloat(vertex.position.y))
	}
}

protocol VertexSource {
	func toVertices() -> [CirqueVertex]
}

protocol Renderer {
	var renderTargetSize: CGSize { get set }
	func render(_ vertices: VertexSource)
}

extension Trail : VertexSource {
	func toVertices() -> [CirqueVertex] {
		// Inner and outer vertices for each segment
		let segments = zip(self.angles, self.distances)
		let stroke = zip(self.points, segments)
		
		var vertices: [CirqueVertex] = []
		
		for segment in stroke {
			let pC = segment.0
			let angle = segment.1.0
			let length = segment.1.1
			let width = CGFloat(4.0) + log2(length)
			let span = CGVector(dx: sin(angle) * width / 2.0, dy: -cos(angle) * width / 2.0)
			
			let pL = CirqueVertex(position: vector_float4(Float(pC.x + span.dx), Float(pC.y + span.dy), 0.0, 1.0))
			let pR = CirqueVertex(position: vector_float4(Float(pC.x - span.dx), Float(pC.y - span.dy), 0.0, 1.0))
			
			vertices.append(pL)
			vertices.append(pR)
		}
		
		return vertices
	}
}

// MARK: Base view

class CirqueView: UIView {
	var renderers: [Renderer] = []
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func didMoveToWindow() {
		contentScaleFactor = 2.0
		renderers = setupRenderers()
	}
	
	func render(_ model: Circle) {
		renderers[0].render(model.segments)
		renderers[1].render(model.segments)
	}
}

// MARK: Simulator
#if arch(i386) || arch(x86_64)
extension CirqueView {
	func setupRenderers() -> [Renderer] {
		return [
			SimulatorErrorRenderer(layer: layer),
			SimulatorCircleRenderer(layer: layer)
		]
	}
	
	override func layoutSublayers(of layer: CALayer) {
		guard layer.sublayers != nil else { return }
		
		for subLayer in layer.sublayers! {
			subLayer.frame = layer.frame
		}
	}
}

struct SimulatorCircleRenderer: Renderer {
	let shapeLayer: CAShapeLayer
	
	var renderTargetSize: CGSize {
		get { return shapeLayer.bounds.size }
		set { shapeLayer.bounds.size = renderTargetSize }
	}
	
	init(layer: CALayer) {
		self.shapeLayer = CAShapeLayer()
		layer.addSublayer(self.shapeLayer)
		self.shapeLayer.frame = layer.frame
		self.shapeLayer.strokeColor = UIColor.blue.cgColor
		self.shapeLayer.lineWidth = 4.0
		self.shapeLayer.backgroundColor = UIColor.clear.cgColor
		self.shapeLayer.fillColor = UIColor.clear.cgColor
	}
	
	func render(_ vertices: VertexSource) {
		let vertexArray = vertices.toVertices()
		guard let firstPoint = vertexArray.first else { return }
		
		let trailPath = UIBezierPath()
		let tail = vertexArray[vertexArray.indices.suffix(from: 1)]
		
		trailPath.move(to: CGPoint(vertex: firstPoint))
		for p in tail {
			trailPath.addLine(to: CGPoint(vertex: p))
		}
		
		shapeLayer.path = trailPath.cgPath
	}
}

struct SimulatorErrorRenderer: Renderer {
	let shapeLayer: CAShapeLayer
	
	var renderTargetSize: CGSize {
		get { return shapeLayer.bounds.size }
		set { shapeLayer.bounds.size = renderTargetSize }
	}
	
	init(layer: CALayer) {
		self.shapeLayer = CAShapeLayer()
		layer.addSublayer(self.shapeLayer)
		self.shapeLayer.bounds = layer.bounds
		self.shapeLayer.strokeColor = UIColor.red.cgColor
		self.shapeLayer.lineWidth = 2.0
		self.shapeLayer.backgroundColor = UIColor.white.cgColor
		self.shapeLayer.fillColor = UIColor.clear.cgColor
	}
	
	func render(_ vertices: VertexSource) {
		let vertexArray = vertices.toVertices()
		guard let firstPoint = vertexArray.first else { return }
		
		let trailPath = UIBezierPath()
		
		var i = 1;
		trailPath.move(to: CGPoint(vertex: firstPoint))
		repeat {
			trailPath.move(to: CGPoint(vertex: vertexArray[i])); i = i + 1
			trailPath.addLine(to: CGPoint(vertex: vertexArray[i])); i = i + 1
			trailPath.addLine(to: CGPoint(vertex: vertexArray[i])); i = i + 1
			trailPath.close()
		} while i + 3 < vertexArray.count
		
		shapeLayer.path = trailPath.cgPath
	}
}
	
#else
// MARK: Metal
extension CirqueView {
	typealias LayerType = CAMetalLayer
	
	override class func layerClass() -> AnyClass {
		return LayerType.self
	}
	
	var renderingLayer : LayerType {
		return layer as! LayerType
	}
	
	func setupRenderer() -> Renderer {
		return MetalRenderer(layer: renderingLayer)
	}
	
	override func layoutSublayersOfLayer(layer: CALayer) {
		renderingLayer.frame = layer.bounds
		renderingLayer.drawableSize = CGSize(width: layer.bounds.width * contentScaleFactor, height: layer.bounds.height * contentScaleFactor)
		renderer.renderTargetSize = renderingLayer.drawableSize
	}
}

struct MetalRenderer: Renderer {
	let metalLayer: CAMetalLayer
	
	let device: MTLDevice
	var commandQueue: MTLCommandQueue!
	var commandBuffer: MTLCommandBuffer!

	var multisampleRenderTarget: MTLTexture!
	var pipeline: MTLRenderPipelineState!

	var uniforms: CirqueUniforms!
	
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
		
		// Setup Metal CALayer
		metalLayer.device = device
		metalLayer.pixelFormat = .BGRA8Unorm
	
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
	
	func render(vertices: VertexSource) {
		let vertexArray = vertices.toVertices()
	
		// Fill out vertex buffer
		let trailBuffer = device.newBufferWithBytes(vertexArray,
			length: sizeof(CirqueVertex) * vertexArray.count,
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
		var circlePassDescriptor: MTLRenderPassDescriptor
		circlePassDescriptor = MTLRenderPassDescriptor()
		circlePassDescriptor.colorAttachments[0] = colorAttachmentDescriptor

		let commandBuffer = commandQueue.commandBuffer()
		let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(circlePassDescriptor)

		commandEncoder.setRenderPipelineState(pipeline)

		// Setup uniform buffer
		var uniforms = buildUniforms(renderTargetSize: renderTargetSize)
		withUnsafePointer(&uniforms) { uniformsPtr in
			let uniformBuffer = device.newBufferWithBytes(uniformsPtr,
				length: sizeof(CirqueUniforms),
				options: MTLResourceOptions.CPUCacheModeDefaultCache)
			commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, atIndex: 1)
		}

		commandEncoder.setVertexBuffer(trailBuffer, offset: 0, atIndex: 0)
		if vertexArray.isEmpty == false {
			commandEncoder.drawPrimitives(.TriangleStrip, vertexStart: 0, vertexCount: vertexArray.count)
		}
		commandEncoder.endEncoding()

		commandBuffer.presentDrawable(drawable)

		commandBuffer.commit()
	}
	
	private func buildRenderTarget(renderTargetSize size: CGSize) -> MTLTexture {
		let targetDescriptor = MTLTextureDescriptor()
		targetDescriptor.pixelFormat = metalLayer.pixelFormat
		targetDescriptor.sampleCount = 4
		targetDescriptor.textureType = .Type2DMultisample
		targetDescriptor.width = Int(size.width)
		targetDescriptor.height = Int(size.height)
		return device.newTextureWithDescriptor(targetDescriptor)
	}
	
	private func buildUniforms(renderTargetSize size: CGSize) -> CirqueUniforms {
		var mvpMatrix = ortho2d(0.0, r: Float(renderTargetSize.width), b: Float(renderTargetSize.height), t: 0.0, n: 0.0, f: 1.0)
		// Translate into Metal's NDC space (2x2x1 unit cube)
		mvpMatrix.columns.3.x = -1.0
		mvpMatrix.columns.3.y = +1.0
		return CirqueUniforms(modelViewProjection: mvpMatrix)
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

