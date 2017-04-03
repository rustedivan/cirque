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

typealias AppRenderPath = CGRenderPath
	
struct CGRenderPath : RenderPath {
	typealias Encoder = Void
	
	var targetLayer: CALayer
	var trailRenderer: CGTrailRenderer<Encoder>
	var errorRenderer: CGErrorRenderer<Encoder>
	var bestFitRenderer: CGBestFitRenderer<Encoder>
	
	init(layer: CALayer) {
		targetLayer = layer
		trailRenderer = CGTrailRenderer(layer: layer)
		errorRenderer = CGErrorRenderer(layer: layer)
		bestFitRenderer = CGBestFitRenderer(layer: layer)
	}

	mutating func renderTargetSizeDidChange(to size: CGSize) {
		if size != targetLayer.bounds.size {
			print ("Render target size does not match target layer size")
			return
		}
		
		// TODO: could probably pack CALayer/(device+pxfmt+cmdencoder) into protocol-init
		trailRenderer = CGTrailRenderer(layer: targetLayer)
		errorRenderer = CGErrorRenderer(layer: targetLayer)
		bestFitRenderer = CGBestFitRenderer(layer: targetLayer)
	}
	
	func renderPass(vertices: VertexSource, inRenderPass renderPass: RenderPass, intoEncoder encoder: Encoder) {
		switch renderPass {
		case .trail(let uniforms):
			trailRenderer.render(vertices: vertices,
			                     withUniforms: uniforms,
			                     intoEncoder: encoder)
		case .error(let uniforms):
			errorRenderer.render(vertices: vertices,
			                     withUniforms: uniforms,
			                     intoEncoder: encoder)
		case .bestFit(let uniforms):
			bestFitRenderer.render(vertices: vertices,
			                       withUniforms: uniforms,
			                       intoEncoder: encoder)
		}
	}
	
	func renderFrame(allRenderPasses: () -> ()) {
		trailRenderer.shapeLayer.path = nil
		errorRenderer.shapeLayer.path = nil
		bestFitRenderer.shapeLayer.path = nil
		
		// Run all rendering passes
		allRenderPasses()
	}
}
	
#endif
