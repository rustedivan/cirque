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
		
		activeRenderers = SimulatorRenderPath.setupRenderers(targetLayer: targetLayer)
	}

	mutating func renderTargetSizeDidChange(to size: CGSize) {
		if size != targetLayer.bounds.size {
			print ("Render target size does not match target layer size")
			return
		}
		
		activeRenderers = SimulatorRenderPath.setupRenderers(targetLayer: targetLayer)
	}
	
	func runPasses(renderAllPasses: () -> ()) {
		// Clear all shape paths
		for renderer in activeRenderers.values {
			let shapeRenderer = renderer as! ShapeRenderer
			shapeRenderer.shapeLayer.path = nil
		}
		
		// Run all rendering passes
		renderAllPasses()
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
		                intoCommandEncoder: ())
	}
}

private extension SimulatorRenderPath {
	static func setupRenderers(targetLayer layer: CALayer) -> [RenderPass : Renderer] {
		let errorRenderer = SimulatorErrorRenderer(layer: layer)
		let circleRenderer = SimulatorCircleRenderer(layer: layer)
		let bestFitRenderer = SimulatorBestFitRenderer(layer: layer)
		
		// Register renderers with their passes
		let renderPasses: [RenderPass : Renderer] =
			[.error(progress: 0.0) :	errorRenderer,
			 .trail :									circleRenderer,
			 .bestFit :								bestFitRenderer]
		return renderPasses
	}
}
	
#endif
