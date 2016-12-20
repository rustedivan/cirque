//
//  MetalRenderPath.swift
//  cirque
//
//  Created by Ivan Milles on 2016-11-26.
//  Copyright © 2016 Rusted. All rights reserved.
//

// If building for device (Metal required to compile)
#if !(arch(i386) || arch(x86_64))

import Foundation
import QuartzCore
import simd

typealias AppRenderPath = MetalRenderPath
	
struct MetalRenderPath : RenderPath {
	enum VertexLocations : Int {
		case position = 0
		case uniforms = 1
		case constants = 2
	}
	
	let device: MTLDevice
	let commandQueue: MTLCommandQueue!
	
	var targetLayer: CAMetalLayer
	var multiSampleTarget: MTLTexture
	
	var activeRenderers: [RenderPass : Renderer]
	
	init(layer: CAMetalLayer) {
		// Prepare Metal
		self.device = MTLCreateSystemDefaultDevice()!
		self.commandQueue = device.makeCommandQueue()
		self.targetLayer = layer
		self.targetLayer.device = device
		self.targetLayer.pixelFormat = .bgra8Unorm
		
		let scaledSize = CGSize(width: layer.bounds.size.width * layer.contentsScale,
		                        height: layer.bounds.size.height * layer.contentsScale)
		multiSampleTarget = MetalRenderPath.buildRenderTarget(onDevice: device,
																													pixelFormat: layer.pixelFormat,
																													renderTargetSize: scaledSize)

		self.activeRenderers = MetalRenderPath.setupRenderers(onDevice: device, targetLayer: targetLayer)
	}
	
	mutating func renderTargetSizeDidChange(to size: CGSize) {
		if size != targetLayer.bounds.size {
			print ("Render target size does not match target layer size")
			return
		}
		
		activeRenderers = MetalRenderPath.setupRenderers(onDevice: device, targetLayer: targetLayer)
	}
	
	func runPasses(renderAllPasses: (RenderPath.Encoder) -> ()) {
		guard let drawable = targetLayer.nextDrawable() else {
			print("Drawable buffer exhausted, blocking.")
			return
		}
		
		// Build render pass targeting this drawable
		let colorAttachmentDescriptor = MTLRenderPassColorAttachmentDescriptor()
		colorAttachmentDescriptor.loadAction = .clear
		colorAttachmentDescriptor.storeAction = .multisampleResolve
		colorAttachmentDescriptor.texture = multiSampleTarget
		let backgroundColor = RenderStyle.backgroundColor.vec4
		colorAttachmentDescriptor.clearColor = MTLClearColorMake(Double(backgroundColor.x), Double(backgroundColor.y),
		                                                         Double(backgroundColor.z), Double(backgroundColor.w))
		
		let renderPassDescriptor = MTLRenderPassDescriptor()
		renderPassDescriptor.colorAttachments[0] = colorAttachmentDescriptor
		renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture

		let commandBuffer = commandQueue.makeCommandBuffer()
		let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
		
		// Setup constants for the entire frame
		var frameConstants = CirqueConstants(projectionSize: targetLayer.bounds.size)
		commandEncoder.setVertexBytes(&frameConstants,
		                              length: MemoryLayout<CirqueConstants>.stride,
		                              at: VertexLocations.constants.rawValue)
		
		// Render all passes into this command encoder
		renderAllPasses(commandEncoder)
		
		commandEncoder.endEncoding()
		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
	
	func renderPass(_ renderPass: RenderPass,
	                vertices: VertexSource,
	                intoCommandEncoder commandEncoder: RenderPath.Encoder) {
		guard let renderer = activeRenderers[renderPass] else {
			print("Unregistered render pass: \(renderPass.passIdentifier)")
			raise(SIGSTOP)
			return
		}
		
		renderer.render(vertices: vertices,
		                inRenderPass: renderPass,
		                intoCommandEncoder: commandEncoder)
	}
}

private extension MetalRenderPath {
	
	static func buildRenderTarget(onDevice device: MTLDevice,
	                                      pixelFormat: MTLPixelFormat,
	                                      renderTargetSize size: CGSize) -> MTLTexture {
		let targetDescriptor = MTLTextureDescriptor()
		targetDescriptor.pixelFormat = pixelFormat
		targetDescriptor.sampleCount = 4
		targetDescriptor.textureType = .type2DMultisample
		targetDescriptor.width = Int(size.width)
		targetDescriptor.height = Int(size.height)
		if #available(iOS 10.0, *) {
			targetDescriptor.storageMode = .memoryless
		}
		return device.makeTexture(descriptor: targetDescriptor)
	}
	
	static func setupRenderers(onDevice device: MTLDevice,
	                           targetLayer layer: CAMetalLayer) -> [RenderPass : Renderer] {
		// Prepare Metal path renderers
		let errorRenderer = MetalErrorRenderer(device: device,
		                                       pixelFormat: layer.pixelFormat)
		let circleRenderer = MetalCircleRenderer(device: device,
		                                         pixelFormat: layer.pixelFormat)
		let bestFitRenderer = MetalBestFitRenderer(device: device,
		                                         pixelFormat: layer.pixelFormat)
		
		// Register renderers with their passes
		let renderPasses: [RenderPass : Renderer] =
			[.error(progress: 0.0) :	errorRenderer,		// FIXME: passing parameters in the render pass is wrong
			 .trail :									circleRenderer,
			 .bestFit :								bestFitRenderer]
		return renderPasses
	}
}
	
#endif
