//
//  CirqueView.swift
//  cirque
//
//  Created by Ivan Milles on 24/01/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

import UIKit

// MARK: Base view

class CirqueView: UIView {
	var renderPath: AppRenderPath!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func render(renderState: RenderWorld) {
		renderPath.renderFrame { encoder in
			
			switch renderState {
			case .idle:
				break
			case .drawing(let circle):
				let uniforms = TrailUniforms()
				renderPath.renderPass(vertices: circle.segments,
				                      inRenderPass: .trail(uniforms),
				                      intoEncoder: encoder)
				
			case .analysis(let circle, let fit, let errorArea):
				let uniforms = ErrorAreaUniforms(progress: 1.0,																		 errorFlashIntensity: 0.0)
				renderPath.renderPass(vertices: errorArea,
				                      inRenderPass: .error(uniforms),
				                      intoEncoder: encoder)
				
				let trailUniforms = TrailUniforms()
				renderPath.renderPass(vertices: circle.segments,
				                      inRenderPass: .trail(trailUniforms),
				                      intoEncoder: encoder)
				
				let bestFitUniforms = BestFitUniforms(progress: 1.0, quality: 1.0)
				renderPath.renderPass(vertices: fit,
				                      inRenderPass: .bestFit(bestFitUniforms),
				                      intoEncoder: encoder)
			case .scoring(let circle, _, _):
				let trailUniforms = TrailUniforms()
				renderPath.renderPass(vertices: circle.segments,
				                      inRenderPass: .trail(trailUniforms),
				                      intoEncoder: encoder)
			default: break
			}
		}
	}
	
	override func didMoveToWindow() {
		contentScaleFactor = 2.0
		layer.backgroundColor = UIColor.white.cgColor
	}
	
	override func layoutSublayers(of layer: CALayer) {
		guard layer.sublayers != nil else { return }
		
		layer.frame = layer.bounds
		for subLayer in layer.sublayers! {
			subLayer.frame = layer.frame
		}
		
		if renderPath == nil {
			renderPath = AppRenderPath(layer: renderingLayer)
		}
		
		renderPath.renderTargetSizeDidChange(to: layer.bounds.size)
	}
}

// MARK: Simulator
#if arch(i386) || arch(x86_64)

extension CirqueView {
	typealias LayerType = CALayer
	
	var renderingLayer : LayerType {
		return layer
	}
}
	
#else
// MARK: Metal
	
import Metal
	
extension CirqueView {
	typealias LayerType = CAMetalLayer
	
	override class var layerClass: Swift.AnyClass {
		return LayerType.self
	}
	
	var renderingLayer : LayerType {
		return layer as! LayerType
	}
}
	
#endif
