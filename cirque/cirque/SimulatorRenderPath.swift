//
//  SimulatorRenderPath.swift
//  cirque
//
//  Created by Ivan Milles on 2016-11-26.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Foundation
import QuartzCore
import simd

struct SimulatorRenderPath : RenderPath {
	var targetLayer: CALayer
	var activeRenderers: [RenderPass : Renderer]
	
	init(layer: CALayer, renderPasses: [RenderPass : Renderer]) {
		self.init(renderers: renderPasses)
		self.targetLayer = layer
	}

	init(renderers: [RenderPass : Renderer]) {
		targetLayer = CALayer()
		activeRenderers = renderers
	}
	
	func renderTargetSizeDidChange(to size: CGSize) {
		if size != targetLayer.bounds.size {
			print ("Render target size does not match target layer size")
			return
		}
		
		for renderer in activeRenderers.values {
			renderer.setRenderTargetSize(size: size)
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
		
		renderer.render(vertices, withUniforms: uniforms)
	}
}
