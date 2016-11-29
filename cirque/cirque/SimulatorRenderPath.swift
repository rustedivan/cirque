//
//  SimulatorRenderPath.swift
//  cirque
//
//  Created by Ivan Milles on 2016-11-26.
//  Copyright © 2016 Rusted. All rights reserved.
//

// If building for simulator (Metal not available)
#if arch(i386) || arch(x86_64)

import Foundation
import QuartzCore
import simd

typealias AppRenderPath = SimulatorRenderPath
	
struct SimulatorRenderPath : RenderPath {
	var targetLayer: CALayer
	var activeRenderers: [RenderPass : Renderer]
	
	init(layer: CALayer) {
		self.targetLayer = layer
		let circleRenderer = SimulatorCircleRenderer(layer: layer)
		let errorRenderer = SimulatorErrorRenderer(layer: layer)
		
		// Register renderers with their passes
		let renderPasses: [RenderPass : Renderer] =
			[.error(progress: 0.0) :	errorRenderer,
			 .trail :									circleRenderer]
		activeRenderers = renderPasses
	}

	func renderTargetSizeDidChange(to size: CGSize) {
		if size != targetLayer.bounds.size {
			print ("Render target size does not match target layer size")
			return
		}
		
		for renderer in activeRenderers.values {
			var targetLayer = renderer.renderTarget
			targetLayer.bounds.size = size
			renderer.setRenderTarget(target: targetLayer)
		}
	}
	
	func runPasses(renderAllPasses: () -> ()) {
		// Run all rendering passes
		renderAllPasses()
	}
	
	func renderPass(vertices: VertexSource, inRenderPass renderPass: RenderPass) {
		guard let renderer = activeRenderers[renderPass] else {
			print("Unregistered render pass: \(renderPass.passIdentifier)")
			return
		}
		
		var uniforms = CirqueUniforms()
		
		switch renderPass {
		case .error(let progress):
			uniforms.progress = progress
		default: break
		}
		
		// Setup common uniforms
		// Not used on the simulator path
		// uniforms.modelViewProjection = matrix_identity_float4x4
		
		renderer.render(vertices, withUniforms: uniforms, withQueue: targetLayer.sublayers!)
	}
}

#endif
