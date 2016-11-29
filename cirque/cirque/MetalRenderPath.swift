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
		
		let scaledSize = CGSize(width: layer.drawableSize.width * layer.contentsScale,
		                        height: layer.drawableSize.height * layer.contentsScale)
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
		colorAttachmentDescriptor.clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
		
		let renderPassDescriptor = MTLRenderPassDescriptor()
		renderPassDescriptor.colorAttachments[0] = colorAttachmentDescriptor
		renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture

		let commandBuffer = commandQueue.makeCommandBuffer()
		let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
		
		// Render all passes into this command encoder
		renderAllPasses(commandEncoder)
		
		commandBuffer.commit()
		commandBuffer.present(drawable)
	}
	
	func renderPass(vertices: VertexSource,
	                inRenderPass renderPass: RenderPass,
	                intoCommandEncoder commandEncoder: RenderPath.Encoder) {
		guard let renderer = activeRenderers[renderPass] else {
			print("Unregistered render pass: \(renderPass.passIdentifier)")
			return
		}
		
		// Setup common uniforms
		// Not used on the simulator path
		// uniforms.modelViewProjection = matrix_identity_float4x4
		
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
		return device.makeTexture(descriptor: targetDescriptor)
	}
	
	static func setupRenderers(onDevice device: MTLDevice,
	                           targetLayer layer: CAMetalLayer) -> [RenderPass : Renderer] {
		// Prepare Metal path renderers

		let circleRenderer = MetalCircleRenderer(device: device,
		                                         pixelFormat: layer.pixelFormat)
		let errorRenderer = MetalErrorRenderer()
		
		// Register renderers with their passes
		let renderPasses: [RenderPass : Renderer] =
			[.error(progress: 0.0) :	errorRenderer,
			 .trail :									circleRenderer]
		return renderPasses
	}
}
	
#endif
